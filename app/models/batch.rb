# frozen_string_literal: true
require 'timeout'
require 'aasm'

# A {Batch} groups 1 or more {Request requests} together to enable processing in a
# {Pipeline}. All requests in a batch get usually processed together, although it is
# possible for requests to get removed from a batch in a handful of cases.
class Batch < ApplicationRecord # rubocop:todo Metrics/ClassLength
  include Api::BatchIo::Extensions
  include Api::Messages::FlowcellIo::Extensions
  include Api::Messages::UseqWaferIo::Extensions
  include AASM
  include SequencingQcBatch
  include Commentable
  include Uuid::Uuidable
  include StandardNamedScopes
  include ::Batch::PipelineBehaviour
  include ::Batch::StateMachineBehaviour
  extend EventfulRecord

  # The three states of {Batch} Also @see {SequencingQcBatch}
  # @!attribute state
  #   The main state machine, used to track the batch through the pipeline. Handled by {Batch::StateMachineBehaviour}
  # @!attribute production_state
  #   Also referenced in {Batch::StateMachineBehaviour}. Either nil, or fail. This is updated in Batch#fail_requests and
  #   Batch#fail. The former is used via BatchesController#fail_items, the latter seems to be unused.
  #   Is intended to take precedence over both other states to track failures in-spite of QC results.
  # @!attribute qc_state
  #   Primarily for sequencing batches. See {SequencingQcBatch}. Holds the sequencing QC state

  DEFAULT_VOLUME = 13

  self.per_page = 500

  belongs_to :user
  belongs_to :assignee, class_name: 'User'

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
  has_many :output_labware, -> { distinct }, through: :assets, source: :labware
  has_many :input_labware, -> { distinct }, through: :source_assets, source: :labware

  has_many_events
  has_many_lab_events

  accepts_nested_attributes_for :requests
  broadcast_with_warren

  # Validations for batches
  # For custom validators, create a a validator class extending CustomValidatorBase and
  # add it to the pipeline table.
  validates_with BatchCreationValidator, on: :create, if: :pipeline

  validate :add_dynamic_validations

  after_create :generate_target_assets_for_requests, if: :generate_target_assets_on_batch_create?
  after_commit :rebroadcast

  # Named scope for search by query string behaviour
  scope :for_search_query,
        ->(query) do
          user = User.find_by(login: query)
          if user
            where(user_id: user)
          else
            with_safe_id(query) # Ensures extra long input (most likely barcodes) doesn't throw an exception
          end
        end

  scope :includes_for_ui, -> { limit(5).includes(:user, :assignee, :pipeline) }
  scope :pending_for_ui, -> { where(state: 'pending', production_state: nil).latest_first }
  scope :released_for_ui, -> { where(state: 'released', production_state: nil).latest_first }
  scope :completed_for_ui, -> { where(state: 'completed', production_state: nil).latest_first }
  scope :failed_for_ui, -> { where(production_state: 'fail').includes(:failures).latest_first }
  scope :in_progress_for_ui, -> { where(state: 'started', production_state: nil).latest_first }
  scope :include_pipeline, -> { includes(pipeline: :uuid_object) }
  scope :include_user, -> { includes(:user) }
  scope :include_requests,
        -> do
          includes(
            requests: [
              :uuid_object,
              :request_metadata,
              :request_type,
              { submission: :uuid_object },
              { asset: [:uuid_object, { aliquots: %i[sample tag] }] },
              { target_asset: [:uuid_object, { aliquots: %i[sample tag] }] }
            ]
          )
        end

  scope :latest_first, -> { order(created_at: :desc) }
  scope :most_recent, ->(number) { latest_first.limit(number) }

  # Returns batches owned or assigned to user. Not filter applied if passed :any
  scope :for_user, ->(user) { user == 'all' ? all : where(assignee_id: user).or(where(user_id: user)) }

  scope :for_pipeline, ->(pipeline) { where(pipeline_id: pipeline) }

  delegate :size, to: :requests
  delegate :sequencing?, :generate_target_assets_on_batch_create?, :min_size, to: :pipeline
  delegate :name, to: :workflow, prefix: true

  alias friendly_name id

  def all_requests_are_ready?
    # Checks that SequencingRequests have at least one LibraryCreationRequest in passed status before being processed
    # (as referred by #75102998)
    errors.add :base, 'All requests must be ready to be added to a batch' unless requests.all?(&:ready?)
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

  # Fail was removed from State Machine (as a state) to allow the addition of qc_state column and features
  def fail(reason, comment, ignore_requests = false)
    # We've deprecated the ability to fail a batch but not its requests.
    # Keep this check here until we're sure we haven't missed anything.
    raise StandardError, 'Can not fail batch without failing requests' if ignore_requests

    # create failures
    failures.create(reason: reason, comment: comment, notify_remote: false)

    requests.each do |request|
      request.failures.create(reason: reason, comment: comment, notify_remote: true)
      EventSender.send_fail_event(request, reason, comment, id) unless request.asset && request.asset.resource?
    end

    self.production_state = 'fail'
    save!
  end

  # Fail specific requests on this batch
  def fail_requests(requests_to_fail, reason, comment, fail_but_charge = false) # rubocop:todo Metrics/MethodLength
    ActiveRecord::Base.transaction do
      requests
        .find(requests_to_fail)
        .each do |request|
          logger.debug "SENDING FAIL FOR REQUEST #{request.id}, BATCH #{id}, WITH REASON #{reason}"

          request.customer_accepts_responsibility! if fail_but_charge
          request.failures.create(reason: reason, comment: comment, notify_remote: true)
          EventSender.send_fail_event(request, reason, comment, id)
        end
      update_batch_state(reason, comment)
    end
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

  def event_with_description(name)
    lab_events.order(id: :desc).find_by(description: name)
  end

  def robot_id
    event_with_description('Cherrypick Layout Set')&.descriptor_value('robot_id')
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

  # Sets the position of the requests in the batch based on their asset barcodes.
  # This was done at Lab request to make it easier to order the tubes in the batch.
  def set_position_based_on_asset_barcode
    request_ids_in_position_order = requests.sort_by { |r| r.asset.human_barcode }.map(&:id)
    assign_positions_to_requests!(request_ids_in_position_order)
  end

  # Sets the position of the requests in the batch to their index in the supplied array.
  def assign_positions_to_requests!(request_ids_in_position_order)
    request_ids_in_batch = batch_requests.map(&:request_id)
    # checking for both missing and extra requests
    missing_requests = request_ids_in_batch.any? { |id| request_ids_in_position_order.exclude?(id) }
    extra_requests = request_ids_in_position_order.any? { |id| request_ids_in_batch.exclude?(id) }
    raise StandardError, 'Can only sort all the requests in the batch at once' if missing_requests || extra_requests

    BatchRequest.transaction do
      batch_requests.each do |batch_request|
        batch_request.move_to_position!(request_ids_in_position_order.index(batch_request.request_id) + 1)
      end
    end
  end

  alias ordered_requests requests

  def assigned_user
    assignee.try(:login) || ''
  end

  def start_requests
    requests.with_assets_for_starting_requests.not_failed.map(&:start!)
  end

  # Returns a list of input labware including their barcodes,
  # purposes, and a count of the number of requests associated with the
  # batch. Output depends on Pipeline. Some pipelines return an empty relationship
  #
  # @return [Labware::ActiveRecord_Relation] The associated labware
  def input_labware_report
    pipeline.input_labware requests
  end

  # Returns a list of output labware including their barcodes,
  # purposes, and a count of the number of requests associated with the
  # batch. Output depends on Pipeline. Some pipelines return an empty relationship
  #
  # @return [Labware::ActiveRecord_Relation] The associated labware
  def output_labware_report
    pipeline.output_labware requests.with_target
  end

  def input_plate_group
    source_assets.group_by(&:plate)
  end

  # This looks odd. Why would a request have the same asset as target asset? Why are we filtering them out here?
  def output_plate_group
    requests.select { |r| r.target_asset != r.asset }.map(&:target_asset).select(&:present?).group_by(&:plate)
  end

  def output_plates
    # We use re-order here as batch_requests applies a default sort order to
    # the relationship, which takes preference, even though we're has_many throughing
    return output_labware.sort_by(&:id) if output_labware.loaded?

    output_labware.reorder(id: :asc)
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

  def id_dup
    id
  end

  # Source Labware returns the physical pieces of labware (ie. a plate for wells, but tubes for tubes)
  def source_labware
    input_labware
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
  # rubocop:todo Metrics/MethodLength
  def verify_tube_layout(barcodes, user = nil) # rubocop:todo Metrics/AbcSize
    requests.each do |request|
      barcode = barcodes[request.position - 1]
      unless barcode == request.asset.machine_barcode || barcode == request.asset.human_barcode
        expected_barcode = request.asset.human_barcode
        errors.add(:base, "The tube at position #{request.position} is incorrect: expected #{expected_barcode}.")
      end
    end
    if errors.empty?
      lab_events.create(description: 'Tube layout verified', user: user)
      true
    else
      false
    end
  end

  # rubocop:enable Metrics/MethodLength

  def release_pending_requests
    # We set the unused requests to pending.
    # this is to allow unused well to be cherry-picked again
    requests.each { |request| detach_request(request) if request.started? }
  end

  # Remove the request from the batch and remove asset information
  def remove_request_ids(request_ids, reason = nil, comment = nil)
    ActiveRecord::Base.transaction do
      Request
        .find(request_ids)
        .each do |request|
          request.failures.create(reason: reason, comment: comment, notify_remote: true)
          detach_request(request)
        end
      update_batch_state(reason, comment)
    end
  end

  # Remove a request from the batch and reset it to a point where it can be put back into
  # the pending queue.
  def detach_request(request, current_user = nil)
    ActiveRecord::Base.transaction do
      unless current_user.nil?
        request.add_comment("Used to belong to Batch #{id} removed at #{Time.zone.now}", current_user)
      end
      pipeline.detach_request_from_batch(self, request)
    end
  end

  def return_request_to_inbox(request, current_user = nil)
    ActiveRecord::Base.transaction do
      unless current_user.nil?
        request.add_comment(
          "Used to belong to Batch #{id} returned to inbox unstarted at #{Time.zone.now}",
          current_user
        )
      end
      request.return_pending_to_inbox!
    end
  end

  # rubocop:todo Metrics/MethodLength
  def reset!(current_user) # rubocop:todo Metrics/AbcSize
    ActiveRecord::Base.transaction do
      discard!

      requests.each do |request|
        request.batch = nil
        return_request_to_inbox(request, current_user)
      end

      if requests.last.submission_id.present?
        Request
          .where(submission_id: requests.last.submission_id, state: 'pending')
          .where.not(request_type_id: pipeline.request_type_ids)
          .find_each do |request|
            request.asset_id = nil
            request.save!
          end
      end
    end
  end

  # rubocop:enable Metrics/MethodLength

  # rubocop:todo Metrics/PerceivedComplexity, Metrics/MethodLength, Metrics/AbcSize
  def swap(current_user, batch_info = {}) # rubocop:todo Metrics/CyclomaticComplexity
    return false if batch_info.empty?

    # Find the two lanes that are to be swapped
    batch_request_left =
      BatchRequest.find_by(batch_id: batch_info['batch_1']['id'], position: batch_info['batch_1']['lane']) or
      errors.add('Swap: ', 'The first lane cannot be found')
    batch_request_right =
      BatchRequest.find_by(batch_id: batch_info['batch_2']['id'], position: batch_info['batch_2']['lane']) or
      errors.add('Swap: ', 'The second lane cannot be found')
    return unless batch_request_left.present? && batch_request_right.present?

    ActiveRecord::Base.transaction do
      # Update the lab events for the request so that they reference the batch that the request is moving to
      batch_request_left.request.lab_events.each do |event|
        event.update!(batch_id: batch_request_right.batch_id) if event.batch_id == batch_request_left.batch_id
      end
      batch_request_right.request.lab_events.each do |event|
        event.update!(batch_id: batch_request_left.batch_id) if event.batch_id == batch_request_right.batch_id
      end

      # Swap the two batch requests so that they are correct.  This involves swapping both the batch and the lane but
      # ensuring that the two requests don't clash on position by removing one of them.
      original_left_batch_id, original_left_position, original_right_request_id =
        batch_request_left.batch_id,
        batch_request_left.position,
        batch_request_right.request_id
      batch_request_right.destroy
      batch_request_left.update!(batch_id: batch_request_right.batch_id, position: batch_request_right.position)
      batch_request_right =
        BatchRequest.create!(
          batch_id: original_left_batch_id,
          position: original_left_position,
          request_id: original_right_request_id
        )

      # Finally record the fact that the batch was swapped
      batch_request_left.batch.lab_events.create!(
        description: 'Lane swap',
        # rubocop:todo Layout/LineLength
        message:
          "Lane #{batch_request_right.position} moved to #{batch_request_left.batch_id} lane #{batch_request_left.position}",
        # rubocop:enable Layout/LineLength
        user_id: current_user.id
      )
      batch_request_right.batch.lab_events.create!(
        description: 'Lane swap',
        # rubocop:todo Layout/LineLength
        message:
          "Lane #{batch_request_left.position} moved to #{batch_request_right.batch_id} lane #{batch_request_right.position}",
        # rubocop:enable Layout/LineLength
        user_id: current_user.id
      )
    end

    true
  end

  # rubocop:enable Metrics/AbcSize, Metrics/MethodLength, Metrics/PerceivedComplexity

  def plate_ids_in_study(study)
    Plate.plate_ids_from_requests(requests.for_studies(study))
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
    lab_events.create(
      description: 'Robot verified',
      message: 'Robot verification completed and source volumes updated.',
      user_id: user_id
    )
  end

  def self.prefix
    'BA'
  end

  def self.valid_barcode?(code)
    begin
      split_code = barcode_without_pick_number(code)
      Barcode.barcode_to_human!(split_code, prefix)
    rescue StandardError
      return false
    end

    return false if find_from_barcode(code).nil?

    true
  end

  def self.barcode_without_pick_number(code)
    code.split('-').first
  end

  def self.extract_pick_number(code)
    # expecting format 550000555760-1 with pick number at end
    split_code = code.split('-')
    return Integer(split_code.last) if split_code.size > 1

    # default to 1 if the pick number is not present
    1
  end

  class << self
    def find_by_barcode(code)
      split_code = barcode_without_pick_number(code)
      human_batch_barcode = Barcode.number_to_human(split_code)
      batch = Batch.find_by(barcode: human_batch_barcode)
      batch ||= Batch.find_by(id: human_batch_barcode)

      batch
    end
    alias find_from_barcode find_by_barcode
  end

  def request_count
    requests.count
  end

  def npg_set_state
    if all_requests_qced?
      self.state = 'released'
      qc_complete
      save!
    end
  end

  def downstream_requests_needing_asset(request)
    next_requests_needing_asset = request.next_requests.select { |r| r.asset_id.blank? }
    yield(next_requests_needing_asset) if next_requests_needing_asset.present?
  end

  def rebroadcast
    messengers.each(&:resend)
  end

  def pick_information?
    pipeline.pick_information?(self)
  end

  # Summarise the state encapsulated by state and production_state
  # Essentially a 'fail' production_state over-rides the 'state'
  # We don't use production_state directly as it it 'fail' rather than
  # ' failed'
  # qc_state it kept separate as its a fairly distinct concept and is
  # summarised elsewhere in the interface.
  def displayed_status
    failed? ? 'failed' : state
  end

  private

  # Adding dynamic validations to the model
  def add_dynamic_validations
    validator_class = get_validator_class(pipeline)
    return unless validator_class

    validator = validator_class.new
    validator.validate(self)
  end

  def get_validator_class(pipeline)
    validator_class_name = pipeline&.validator_class_name
    validator_class_name.try(:constantize)
  end

  def all_requests_qced?
    requests.all? { |request| request.asset.resource? || request.events.family_pass_and_fail.exists? }
  end

  # rubocop:todo Metrics/MethodLength
  def generate_target_assets_for_requests # rubocop:todo Metrics/AbcSize
    requests_to_update = []

    asset_type = pipeline.asset_type.constantize
    requests.reload.each do |request|
      next if request.target_asset.present?

      # we need to call downstream request before setting the target_asset
      # otherwise, the request use the target asset to find the next request
      target_asset =
        asset_type.create! do |asset|
          asset.generate_barcode
          asset.generate_name(request.asset.name)
        end

      downstream_requests_needing_asset(request) do |downstream_requests|
        requests_to_update.concat(downstream_requests.map { |r| [r, target_asset.receptacle] })
      end

      request.update!(target_asset:)

      target_asset.parents << request.asset.labware
    end

    requests_to_update.each { |request, asset| request.update!(asset:) }
  end
  # rubocop:enable Metrics/MethodLength
end
