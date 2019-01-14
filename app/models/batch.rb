require 'timeout'
require 'tecan_file_generation'
require 'aasm'

class Batch < ApplicationRecord
  include Api::BatchIO::Extensions
  include Api::Messages::FlowcellIO::Extensions
  include AASM
  include SequencingQcBatch
  include Commentable
  include Uuid::Uuidable
  include StandardNamedScopes
  include ::Batch::PipelineBehaviour
  include ::Batch::StateMachineBehaviour
  include ::Batch::TecanBehaviour
  extend EventfulRecord

  DEFAULT_VOLUME = 13

  self.per_page = 500

  belongs_to :user, foreign_key: 'user_id'
  belongs_to :assignee, class_name: 'User', foreign_key: 'assignee_id'

  has_many :failures, as: :failable
  has_many :messengers, as: :target, inverse_of: :target
  has_many :batch_requests, -> { includes(:request).order(:position, :request_id) }, inverse_of: :batch
  has_many :requests, -> { distinct }, through: :batch_requests, inverse_of: :batch
  has_many :assets, through: :requests, source: :target_asset
  has_many :target_assets, through: :requests
  has_many :source_assets, -> { distinct }, through: :requests, source: :asset
  has_many :submissions, -> { distinct }, through: :requests
  has_many :orders, -> { distinct }, through: :requests
  has_many :studies, -> { distinct }, through: :orders
  has_many :projects, -> { distinct }, through: :orders
  has_many :aliquots, -> { distinct }, through: :source_assets
  has_many :samples, -> { distinct }, through: :source_assets, source: :samples

  has_many_events
  has_many_lab_events

  accepts_nested_attributes_for :requests
  broadcast_via_warren

  validate :requests_have_same_read_length, :cluster_formation_requests_must_be_over_minimum, :all_requests_are_ready?, on: :create

  after_create :generate_target_assets_for_requests, if: :need_target_assets_on_requests?
  after_commit :rebroadcast

  # Named scope for search by query string behavior
  scope :for_search_query, ->(query) {
    user = User.find_by(login: query)
    if user
      where(user_id: user)
    else
      with_safe_id(query) # Ensures extra long input (most likely barcodes) doesn't throw an exception
    end
  }

  scope :for_lab_searches_display, -> {}

  scope :includes_for_ui,    -> { limit(5).includes(:user, :assignee, :pipeline) }
  scope :pending_for_ui,     -> { where(state: 'pending',   production_state: nil).latest_first }
  scope :released_for_ui,    -> { where(state: 'released',  production_state: nil).latest_first }
  scope :completed_for_ui,   -> { where(state: 'completed', production_state: nil).latest_first }
  scope :failed_for_ui,      -> { where(production_state: 'fail').includes(:failures).latest_first }
  scope :in_progress_for_ui, -> { where(state: 'started', production_state: nil).latest_first }
  scope :include_pipeline, -> { includes(pipeline: :uuid_object) }
  scope :include_user, -> { includes(:user) }
  scope :include_requests, -> {
    includes(requests: [
      :uuid_object, :request_metadata, :request_type,
      { submission: :uuid_object },
      { asset: [:uuid_object, { aliquots: [:sample, :tag] }] },
      { target_asset: [:uuid_object, { aliquots: [:sample, :tag] }] }
    ])
  }

  scope :latest_first, -> { order(created_at: :desc) }
  scope :most_recent, ->(number) { latest_first.limit(number) }

  delegate :size, to: :requests
  delegate :sequencing?, to: :pipeline

  alias friendly_name id

  def study
    studies.first
  end
  deprecate study: 'Batches can belong to multiple studies'

  def all_requests_are_ready?
    # Checks that SequencingRequests have at least one LibraryCreationRequest in passed status before being processed (as refered by #75102998)
    unless requests.all?(&:ready?)
      errors.add :base, 'All requests must be ready to be added to a batch'
    end
  end

  def subject_type
    sequencing? ? 'flowcell' : 'batch'
  end

  def eventful_studies
    requests.reduce([]) { |studies, request| studies.concat(request.eventful_studies) }.uniq
  end

  def flowcell
    self if sequencing?
  end

  def cluster_formation_requests_must_be_over_minimum
    if (!pipeline.min_size.nil?) && (requests.size < pipeline.min_size)
      errors.add :base, "You must create batches of at least #{pipeline.min_size} requests in the pipeline #{pipeline.name}"
    end
  end

  def requests_have_same_read_length
    unless pipeline.is_read_length_consistent_for_batch?(self)
      errors.add :base, "The selected requests must have the same values in their 'Read length' field."
    end
  end

  # Fail was removed from State Machine (as a state) to allow the addition of qc_state column and features
  def fail(reason, comment, ignore_requests = false)
    # We've deprecated the ability to fail a batch but not its requests.
    # Keep this check here until we're sure we haven't missed anything.
    raise StandardError, 'Can not fail batch without failing requests' if ignore_requests

    # create failures
    failures.create(reason: reason, comment: comment, notify_remote: false)

    requests.each do |request|
      request.failures.create(reason: reason, comment: comment, notify_remote: true)
      unless request.asset && request.asset.resource?
        EventSender.send_fail_event(request.id, reason, comment, id)
      end
    end

    self.production_state = 'fail'
    save!
  end

  # Fail specific items on this batch
  def fail_batch_items(requests_to_fail, reason, comment, fail_but_charge = false)
    checkpoint = true

    requests_to_fail.each do |key, value|
      if value == 'on'
        logger.debug "SENDING FAIL FOR REQUEST #{key}, BATCH #{id}, WITH REASON #{reason}"
        unless key == 'control'
          ActiveRecord::Base.transaction do
            request = requests.find(key)
            request.customer_accepts_responsibility! if fail_but_charge
            request.failures.create(reason: reason, comment: comment, notify_remote: true)
            EventSender.send_fail_event(request.id, reason, comment, id)
          end
        end
      else
        checkpoint = false
      end
    end

    update_batch_state(reason, comment) if checkpoint
  end

  def update_batch_state(reason, comment)
    if requests.all?(&:terminated?)
      failures.create(reason: reason, comment: comment, notify_remote: false)
      self.production_state = 'fail'
      save!
    end
  end

  def failed?
    production_state == 'fail'
  end

  # Tests whether this Batch has any associated LabEvents
  def has_event(event_name)
    lab_events.any? { |event| event_name.downcase == event.description.try(:downcase) }
  end

  def underrun
    has_limit? ? (item_limit - batch_requests.size) : 0
  end

  def control
    requests.detect { |request| request.try(:asset).try(:resource?) }
  end

  def has_control?
    control.present?
  end

  # Sets the position of the requests in the batch to their index in the array.
  def assign_positions_to_requests!(request_ids_in_position_order)
    disparate_ids = batch_requests.map(&:request_id) - request_ids_in_position_order
    raise StandardError, 'Can only sort all requests at once' unless disparate_ids.empty?

    BatchRequest.transaction do
      batch_requests.each do |batch_request|
        batch_request.move_to_position!(request_ids_in_position_order.index(batch_request.request_id) + 1)
      end
    end
  end

  alias_method :ordered_requests, :requests

  def shift_item_positions(position, number)
    return unless number

    BatchRequest.transaction do
      batch_requests.each do |batch_request|
        next unless batch_request.position >= position
        next if batch_request.request.asset.try(:resource?)

        batch_request.move_to_position!(batch_request.position + number)
      end
    end
  end

  def assigned_user
    assignee.try(:login) || ''
  end

  def start_requests
    requests.with_assets_for_starting_requests.not_failed.map(&:start!)
  end

  def input_group
    pipeline.group_requests requests
  end

  def input_plate_group
    source_assets.group_by(&:plate)
  end

  def input_group_sorted_by_map_id
    source_assets.sort_by(&:map_id).group_by(&:parent)
  end

  def output_group
    pipeline.group_requests requests.with_target, by_target: true
  end

  def output_group_by_holder
    pipeline.group_requests requests.with_target, by_target: true, group_by_holder_only: true
  end

  # This looks odd. Why would a request have the same asset as target asset? Why are we filtering them out here?
  def output_plate_group
    requests.select { |r| r.target_asset != r.asset }.map(&:target_asset).select(&:present?).group_by(&:plate)
  end

  def output_plates
    holder_ids = Request.get_target_plate_ids(request_ids)
    Plate.find(holder_ids)
  end

  def first_output_plate
    Plate.output_by_batch(self).with_wells_and_requests.first
  end

  def output_plate_purpose
    output_plates[0].plate_purpose unless output_plates[0].nil?
  end

  def output_plate_role
    requests.first.try(:role)
  end

  def plate_group_barcodes
    return nil unless pipeline.group_by_parent || requests.first.target_asset.is_a?(Well)

    output_plate_group.presence || input_plate_group
  end

  def plate_barcode(barcode)
    barcode.presence || requests.first.target_asset.plate.human_barcode
  end

  def mpx_library_name
    mpx_name = ''
    if multiplexed? && requests.size > 0
      mpx_library_tube = requests.first.target_asset.child
      if mpx_library_tube.present?
        mpx_name = mpx_library_tube.name
      end
    end
    mpx_name
  end

  def display_tags?
    multiplexed?
  end

  def multiplexed_items_with_unique_library_ids
    requests.map { |r| r.target_asset.children }.flatten.uniq
  end

  # Source Labware returns the physical pieces of lawbare (ie. a plate for wells, but stubes for tubes)
  def source_labware
    requests.map(&:asset).map(&:labware).uniq
  end

  #
  # Verifies that provided barcodes are in the correct locations according to the
  # request organization within the batch.
  # Either returns true, and logs the event or returns false.
  #
  # @param [Array<Integer>] barcodes An array of 1-7 digit long barcodes
  # @param [User] user The user validating the barcode layout
  #
  # @return [Bool] true if the layout is correct, false otherwise
  #
  def verify_tube_layout(barcodes, user = nil)
    requests.each do |request|
      barcode = barcodes[request.position - 1]
      unless barcode == request.asset.machine_barcode
        expected_barcode = request.asset.human_barcode
        errors.add(:base, "The tube at position #{request.position} is incorrect: expected #{expected_barcode}.")
      end
    end
    if errors.empty?
      lab_events.create(description: 'Tube layout verified', user: user)
      return true
    else
      return false
    end
  end

  def release_pending_requests
    # We set the unusued requests to pendind.
    # this is to allow unused well to be cherry-picked again
    requests.each do |request|
      detach_request(request) if request.started?
    end
  end

  # Remove the request from the batch and remove asset information
  def remove_request_ids(request_ids, reason = nil, comment = nil)
    ActiveRecord::Base.transaction do
      request_ids.each do |request_id|
        request = Request.find(request_id)
        next if request.nil?

        request.failures.create(reason: reason, comment: comment, notify_remote: true)
        detach_request(request)
      end
      update_batch_state(reason, comment)
    end
  end
  alias_method(:recycle_request_ids, :remove_request_ids)

  # Remove a request from the batch and reset it to a point where it can be put back into
  # the pending queue.
  def detach_request(request, current_user = nil)
    ActiveRecord::Base.transaction do
      request.add_comment("Used to belong to Batch #{id} removed at #{Time.now}", current_user) unless current_user.nil?
      pipeline.detach_request_from_batch(self, request)
    end
  end

  def return_request_to_inbox(request, current_user = nil)
    ActiveRecord::Base.transaction do
      request.add_comment("Used to belong to Batch #{id} returned to inbox unstarted at #{Time.now}", current_user) unless current_user.nil?
      request.return_pending_to_inbox!
    end
  end

  def remove_link(request)
    request.batch = nil
  end

  def reset!(current_user)
    ActiveRecord::Base.transaction do
      discard!

      requests.each do |request|
        remove_link(request) # Remove link in all types of pipelines
        return_request_to_inbox(request, current_user)
      end

      if requests.last.submission_id.present?
        Request.where(submission_id: requests.last.submission_id, state: 'pending')
               .where.not(request_type_id: pipeline.request_type_ids).find_each do |request|
          request.asset_id = nil
          request.save!
        end
      end
    end
  end

  def parent_of_purpose(name)
    return nil if requests.empty?

    requests.first.asset.ancestors.joins(
      'INNER JOIN plate_purposes ON assets.plate_purpose_id = plate_purposes.id'
    )
            .find_by(plate_purposes: { name: name })
  end

  def swap(current_user, batch_info = {})
    return false if batch_info.empty?

    # Find the two lanes that are to be swapped
    batch_request_left  = BatchRequest.find_by(batch_id: batch_info['batch_1']['id'], position: batch_info['batch_1']['lane']) or errors.add('Swap: ', 'The first lane cannot be found')
    batch_request_right = BatchRequest.find_by(batch_id: batch_info['batch_2']['id'], position: batch_info['batch_2']['lane']) or errors.add('Swap: ', 'The second lane cannot be found')
    return unless batch_request_left.present? and batch_request_right.present?

    ActiveRecord::Base.transaction do
      # Update the lab events for the request so that they reference the batch that the request is moving to
      batch_request_left.request.lab_events.each  { |event| event.update!(batch_id: batch_request_right.batch_id) if event.batch_id == batch_request_left.batch_id  }
      batch_request_right.request.lab_events.each { |event| event.update!(batch_id: batch_request_left.batch_id)  if event.batch_id == batch_request_right.batch_id }

      # Swap the two batch requests so that they are correct.  This involves swapping both the batch and the lane but ensuring that the
      # two requests don't clash on position by removing one of them.
      original_left_batch_id, original_left_position, original_right_request_id = batch_request_left.batch_id, batch_request_left.position, batch_request_right.request_id
      batch_request_right.destroy
      batch_request_left.update!(batch_id: batch_request_right.batch_id, position: batch_request_right.position)
      batch_request_right = BatchRequest.create!(batch_id: original_left_batch_id, position: original_left_position, request_id: original_right_request_id)

      # Finally record the fact that the batch was swapped
      batch_request_left.batch.lab_events.create!(description: 'Lane swap', message: "Lane #{batch_request_right.position} moved to #{batch_request_left.batch_id} lane #{batch_request_left.position}", user_id: current_user.id)
      batch_request_right.batch.lab_events.create!(description: 'Lane swap', message: "Lane #{batch_request_left.position} moved to #{batch_request_right.batch_id} lane #{batch_request_right.position}", user_id: current_user.id)
    end

    true
  end

  def plate_ids_in_study(study)
    Plate.plate_ids_from_requests(requests.for_studies(study))
  end

  def space_left
    [item_limit - batch_requests.count, 0].max
  end

  def add_control(control_name, control_count)
    asset = Asset.find_by(name: control_name, resource: true)

    control_count = space_left if control_count == 0

    first_control = [3, (item_limit - control_count)].min

    ActiveRecord::Base.transaction do
      shift_item_positions(first_control + 1, control_count)
      (1..control_count).each do |index|
        batch_requests.create!(
          request: pipeline.control_request_type.create_control!(asset: asset, study_id: 198),
          position: first_control + index
        )
      end
    end
    control_count
  end

  def total_volume_to_cherrypick
    request = requests.first
    return DEFAULT_VOLUME unless request.asset.is_a?(Well)
    return DEFAULT_VOLUME unless request.target_asset.is_a?(Well)

    request.target_asset.get_requested_volume
  end

  def robot_verified!(user_id)
    return if has_event('robot verified')

    pipeline.robot_verified!(self)
    lab_events.create(description: 'Robot verified', message: 'Robot verification completed and source volumes updated.', user_id: user_id)
  end

  def self.prefix
    'BA'
  end

  def self.valid_barcode?(code)
    begin
      Barcode.barcode_to_human!(code, prefix)
    rescue
      return false
    end

    if find_from_barcode(code).nil?
      return false
    end

    true
  end

  class << self
    def find_by_barcode(code)
      human_batch_barcode = Barcode.number_to_human(code)
      batch = Batch.find_by(barcode: human_batch_barcode)
      batch ||= Batch.find_by(id: human_batch_barcode)

      batch
    end
    alias_method :find_from_barcode, :find_by_barcode
  end

  def request_count
    requests.count
  end

  def show_actions?
    released? == false or
      pipeline.class.const_get(:ALWAYS_SHOW_RELEASE_ACTIONS)
  end

  def npg_set_state
    if all_requests_qced?
      self.state = 'released'
      qc_complete
      save!
    end
  end

  def show_fail_link?
    released? && sequencing?
  end

  def downstream_requests_needing_asset(request)
    next_requests_needing_asset = request.next_requests.select { |r| r.asset_id.blank? }
    yield(next_requests_needing_asset) unless next_requests_needing_asset.blank?
  end

  def rebroadcast
    messengers.each(&:queue_for_broadcast)
  end

  private

  def all_requests_qced?
    requests.all? do |request|
      request.asset.resource? ||
        request.events.family_pass_and_fail.exists?
    end
  end

  def generate_target_assets_for_requests
    requests_to_update, asset_links = [], []

    asset_type = pipeline.asset_type.constantize
    requests.reload.each do |request|
      # we need to call downstream request before setting the target_asset
      # otherwise, the request use the target asset to find the next request
      target_asset = asset_type.create! do |asset|
        asset.generate_barcode
        asset.generate_name(request.asset.name)
      end

      downstream_requests_needing_asset(request) do |downstream_requests|
        requests_to_update.concat(downstream_requests.map { |r| [r.id, target_asset.id] })
      end

      request.update!(target_asset: target_asset)

      # All links between the two assets as new, so we can bulk create them!
      asset_links << [request.asset.id, request.target_asset.id]
    end

    AssetLink::BuilderJob.create(asset_links)

    requests_to_update.each do |request_details|
      Request.find(request_details.first).update!(asset_id: request_details.last)
    end
  end

  def need_target_assets_on_requests?
    pipeline.need_target_assets_on_requests?
  end
end
