require 'timeout'
require "tecan_file_generation"

include Sanger::Robots::Tecan

class Batch < ActiveRecord::Base
  include Api::BatchIO::Extensions
  cattr_reader :per_page
  @@per_page = 500
  include AASM
  include SequencingQcBatch
  include Commentable
  include Uuid::Uuidable
  include ModelExtensions::Batch
  include StandardNamedScopes

  extend EventfulRecord
  has_many_events
  has_many_lab_events

  DEFAULT_VOLUME = 13

  include ::Batch::PipelineBehaviour
  include ::Batch::StateMachineBehaviour
  include ::Batch::TecanBehaviour

  belongs_to :user, :foreign_key => "user_id"
  belongs_to :assignee, :class_name => "User", :foreign_key => "assignee_id"

  has_many :failures, :as => :failable

  # Named scope for search by query string behavior
  named_scope :for_search_query, lambda { |query|
    conditions = [ 'id=?', query ]
    if user = User.find_by_login(query)
      conditions = [ 'user_id=?', user.id ]
    end
    { :conditions => conditions }
  }

  named_scope :includes_for_ui,    { :limit => 5, :include => :user }
  named_scope :pending_for_ui,     { :conditions => { :state => 'pending',   :production_state => nil    }, :order => 'created_at DESC' }
  named_scope :released_for_ui,    { :conditions => { :state => 'released',  :production_state => nil    }, :order => 'created_at DESC' }
  named_scope :completed_for_ui,   { :conditions => { :state => 'completed', :production_state => nil    }, :order => 'created_at DESC' }
  named_scope :failed_for_ui,      { :conditions => {                        :production_state => 'fail' }, :order => 'created_at DESC' }
  named_scope :in_progress_for_ui, { :conditions => [ 'state NOT IN (?) AND production_state IS NULL', [ 'pending', 'released', 'completed' ] ], :order => 'created_at DESC' }

  delegate :size, :to => :requests

  # Fail was removed from State Machine (as a state) to allow the addition of qc_state column and features
  def fail(reason, comment, ignore_requests=false)
    # create failures
    self.failures.create(:reason => reason, :comment => comment, :notify_remote => false)
    unless ignore_requests

      self.requests.each do |request|
        request.failures.create(:reason => reason, :comment => comment, :notify_remote => true)
        unless request.asset && request.asset.resource?
          EventSender.send_fail_event(request.id, reason, comment, self.id)
        end
      end

    end
    self.production_state = "fail"
    self.save!
  end

  # Fail specific items on this batch
  def fail_batch_items(requests, reason, comment)
    checkpoint = true

    requests.each do |key, value|
      if value == "on"
        logger.debug "SENDING FAIL FOR REQUEST #{key}, BATCH #{self.id}, WITH REASON #{reason}"
        unless key == "control"
          ActiveRecord::Base.transaction do
            request = self.requests.find(key)
            request.failures.create(:reason => reason, :comment => comment, :notify_remote => true)
            EventSender.send_fail_event(request.id, reason, comment, self.id)
          end
        end
      else
        checkpoint = false
      end
    end

    # There is a slight difference between fail and fail_batch_items.
    # fail_batch_items checks if all the values on request_ids are "on", which is safe.
    # While fail method fails the batch and the items without checking
    if checkpoint == true && requests.size == self.requests.size
      self.failures.create(:reason => reason, :comment => comment, :notify_remote => false)
      self.production_state = "fail"
      self.save!
    end
  end

  def failed?
    self.production_state == "fail"
  end

  # Used in auto_batch view to disable the submit button if the batch was already passed to Auto QC
  def in_process?
    statuses = qc_states
    statuses.delete_at(0)
    statuses.include?(self.qc_state)
  end

  # Tests whether this Batch has any associated LabEvents
  def has_event(event_name)
    lab_events.any? { |event| event_name.downcase == event.description.try(:downcase) }
  end

  def underrun
    self.has_limit? ? (self.item_limit - self.requests.size) : 0
  end

  def control
    self.requests.detect { |request| request.try(:asset).try(:resource?) }
  end

  def has_control?
    !self.control.nil?
  end

  # Sets the position of the requests in the batch to their index in the array.
  def assign_positions_to_requests!(request_ids_in_position_order)
    disparate_ids = batch_requests.map(&:request_id) - request_ids_in_position_order
    raise StandardError, "Can only sort all requests at once" unless disparate_ids.empty?

    BatchRequest.transaction do
      batch_requests.each do |batch_request|
        batch_request.move_to_position!(request_ids_in_position_order.index(batch_request.request_id)+1)
      end
    end
  end

  def shift_item_positions(position, number)
    return unless number
    BatchRequest.transaction do
      batch_requests.each do |batch_request|
        next unless batch_request.position >= position
        next if batch_request.request.asset.try(:resource?)
        batch_request.move_to_position!(batch_request.position + number)
      end
    end

    ordered_requests
  end

  def assigned_user
    self.assignee.try(:login) || ''
  end

  def start_requests
    self.requests.with_assets_for_starting_requests.not_failed.map(&:start!)
  end

  def input_group
    pipeline.group_requests requests
  end

  def input_plate_group
    requests.map(&:asset).select(&:present?).group_by(&:plate)
  end

  def input_group_sorted_by_map_id
    requests.map(&:asset).select(&:present?).sort_by(&:map_id).group_by(&:parent)
  end

  def output_group
    pipeline.group_requests requests.with_target, :by_target => true
  end

  def output_group_by_holder
    pipeline.group_requests requests.with_target, :by_target => true, :group_by_holder_only => true
  end

  def output_plate_group
    requests.select { |r| r.target_asset != r.asset}.map(&:target_asset).select(&:present?).group_by(&:plate)
  end

  def output_plates
    holder_ids = Request.get_target_holder_asset_id_map(request_ids).values
    Plate.find(holder_ids, :group => :barcode)


    #TODO: replace output_plates SQL with proper rails way of doing things with equal speed
    #Plate.find_by_sql("select plate_assets.* from batch_requests batch_requests, requests requests, assets assets,
      #assets plate_assets where batch_requests.batch_id = #{self.id} and
      #batch_requests.request_id = requests.id and
      #requests.target_asset_id is not null and
      #requests.target_asset_id = assets.id and
      #assets.holder_id = plate_assets.id group by plate_assets.barcode")
  end

  # Returns the plate_purpose of the first output plate associated with the batch,
  # this is currently assumed to the same for all output plates.
  def output_plate_purpose
    output_plates[0].plate_purpose unless output_plates[0].nil?
  end

  # Set the plate_purpose of all output plates associated with this batch
  def set_output_plate_purpose(plate_purpose)
    raise "This batch has no output plates to assign a purpose to!" if output_plates.blank?

    output_plates.each { |plate|
      plate.plate_purpose = plate_purpose
      plate.save!
    }

    true
  end



  def output_plate_in_batch?(barcode)
    return false if barcode.nil?
    return false if Plate.find_by_barcode(barcode).nil?
    output_plates.any? { |plate| plate.barcode == barcode }
  end


  def plate_group_barcodes
    return nil unless pipeline.group_by_parent || requests.first.target_asset.is_a?(Well)
    latest_plate_group = output_plate_group
    return latest_plate_group unless latest_plate_group.empty?
    return input_plate_group
  end

  def plate_barcode(barcode)
    if barcode
      return barcode
    else
      return requests.first.target_asset.plate.barcode
    end
  end

  def mpx_library_name
    mpx_name = ""
    if self.multiplexed? && self.requests.size > 0
      mpx_library_tube = self.requests[0].target_asset.child
      if ! mpx_library_tube.nil?
        mpx_name = mpx_library_tube.name
      end
    end
    mpx_name
  end

  def display_tags?
    self.multiplexed?
  end


  # Returns meaningful events excluding discriptors/descriptor_fields clutter
  def formatted_events
    ev = self.lab_events
    d = []
    unless ev.empty?
      ev.sort_by{ |i| i[:created_at] }.each do |t|
        if t.descriptors
          if g = t.descriptor_value("task")
            d << {"task" => g, "description" => t.description, "message" => t.message, "data" => t.data, "created_at" => t.created_at}
          end
        end
      end
    end
    d
  end


  def multiplexed_items_with_unique_library_ids
    requests.map { |r| r.target_asset.children }.flatten.uniq
  end

  def ordered_requests(options=nil)
    batch_requests.ordered.all(options).map(&:request).compact
  end

  def assets
    requests.map(&:target_asset)
  end

  def verify_tube_layout(barcodes, user = nil)
    self.requests.each do |request|
      barcode = barcodes["#{request.position(self)}"]
      unless barcode.blank? || barcode == "0"
        unless barcode.to_i == request.asset.barcode.to_i
          self.errors.add_to_base("The tube at position #{request.position(self)} is incorrect.")
        end
      end
    end
    if self.errors.empty?
      self.lab_events.create(:description => "Tube layout verified", :user => user)
      return true
    else
      return false
    end
  end

  def release_pending_requests
    # We set the unusued requests to pendind.
    # this is to allow unused well to be cherry-picked again
    requests.each do |request|
      detach_request(request) if request.state == "started"
    end
  end

  # Remove the request from the batch and remove asset information
  def remove_request_ids(request_ids)
    request_ids.each do |request_id|
      request = Request.find(request_id)
      next if request.nil?
      self.detach_request(request)
    end
  end
  alias_method(:recycle_request_ids, :remove_request_ids)

  # Remove a request from the batch and reset it to a point where it can be put back into
  # the pending queue.
  def detach_request(request, current_user=nil)
    ActiveRecord::Base.transaction do
      request.add_comment("Used to belong to Batch #{self.id} removed at #{Time.now()}", current_user) unless current_user.nil?
      self.pipeline.detach_request_from_batch(self, request)
    end
  end

  def remove_link(request)
    request.batches-=[self]
  end

  def reset!(current_user)
    ActiveRecord::Base.transaction do
      self.requests.each do |request|
        self.remove_link(request) # Remove link in all types of pipelines
        self.detach_request(request, current_user)
      end

      if self.requests.last.submission_id.present?
        requests = Request.find_all_by_submission_id(self.requests.last.submission_id,
          :conditions => ['state = ? AND request_type_id NOT IN (?)', 'pending', self.pipeline.request_type_ids])
        requests.each do |request|
          request.asset_id = nil
          request.save!
        end
      end

      self.destroy
    end
  end

  def swap(current_user, batch_info = {})
    return false if batch_info.empty?

    # Find the two lanes that are to be swapped
    batch_request_left  = BatchRequest.find_by_batch_id_and_position(batch_info['batch_1']['id'], batch_info['batch_1']['lane']) or self.errors.add("Swap: ", "The first lane cannot be found")
    batch_request_right = BatchRequest.find_by_batch_id_and_position(batch_info['batch_2']['id'], batch_info['batch_2']['lane']) or self.errors.add("Swap: ", "The second lane cannot be found")
    return unless batch_request_left.present? and batch_request_right.present?

    ActiveRecord::Base.transaction do
      # Update the lab events for the request so that they reference the batch that the request is moving to
      batch_request_left.request.lab_events.each  { |event| event.update_attributes!(:batch_id => batch_request_right.batch_id) if event.batch_id == batch_request_left.batch_id  }
      batch_request_right.request.lab_events.each { |event| event.update_attributes!(:batch_id => batch_request_left.batch_id)  if event.batch_id == batch_request_right.batch_id }

      # Swap the two batch requests so that they are correct.  This involves swapping both the batch and the lane but ensuring that the
      # two requests don't clash on position by removing one of them.
      original_left_batch_id, original_left_position, original_right_request_id = batch_request_left.batch_id, batch_request_left.position, batch_request_right.request_id
      batch_request_right.destroy
      batch_request_left.update_attributes!(:batch_id => batch_request_right.batch_id, :position => batch_request_right.position)
      batch_request_right = BatchRequest.create!(:batch_id => original_left_batch_id, :position => original_left_position, :request_id => original_right_request_id)

      # Finally record the fact that the batch was swapped
      batch_request_left.batch.lab_events.create!(:description => "Lane swap", :message => "Lane #{batch_request_right.position} moved to #{batch_request_left.batch_id} lane #{batch_request_left.position}", :user_id => current_user.id)
      batch_request_right.batch.lab_events.create!(:description => "Lane swap", :message => "Lane #{batch_request_left.position} moved to #{batch_request_right.batch_id} lane #{batch_request_right.position}", :user_id => current_user.id)
    end

    return true
  end

  def study
    self.studies.first
  end

  #TODO has_many :aliquots, :finder_sql => ...
  def aliquots
    self.requests.map(&:asset).compact.map(&:aliquots).flatten.compact
  end

  #TODO has_many :orders, :finder_sql => ...
  def orders
    self.requests.map(&:submission).compact.map(&:orders).flatten.compact
  end

  #not efficient, but not used often
  def studies
    #we use order and not aliquots because aliquots can be empty
    self.orders.map(&:study).compact.uniq
  end

  def projects
    self.orders.map(&:project).compact
  end

  def requests_by_study(*args)
    self.requests.for_studies(*args).all
  end
  deprecate :requests_by_study

  def plate_ids_in_study(study)
    Plate.plate_ids_from_requests(self.requests.for_studies(study))
  end

  def space_left
    [self.item_limit - self.batch_requests.count, 0].max
  end

  def add_control(control_name, control_count)
    asset   = Asset.find_by_name_and_resource(control_name, true)

    control_count  = self.space_left if control_count == 0

    first_control = [3, (self.item_limit - control_count)].min

    ActiveRecord::Base.transaction do
      self.shift_item_positions(first_control+1, control_count)
      (1..control_count).each do |index|
        self.batch_requests.create!(
          :request  => self.pipeline.control_request_type.create_control!(:asset => asset, :study_id => 198),
          :position => first_control+index
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

  def self.prefix
    "BA"
  end

  def self.valid_barcode?(code)
    begin
      Barcode.barcode_to_human!(code, self.prefix)
    rescue
      return false
    end

    if self.find_from_barcode(code).nil?
      return false
    end

    true
  end

  def self.find_from_barcode(code)
    human_batch_barcode = Barcode.number_to_human(code)
    batch = Batch.find_by_barcode(human_batch_barcode)
    batch ||= Batch.find_by_id(human_batch_barcode)

    batch
  end

  def request_count
    BatchRequest.count(:conditions => "batch_id = #{self.id}")
  end

  def pulldown_batch_report
    report_data = FasterCSV.generate( :row_sep => "\r\n") do |csv|
      csv << pulldown_report_headers

      self.requests.each do |request|
        raise 'Invalid request data' unless  request.valid_request_for_pulldown_report?
        well = request.asset
        #TODO[mb14] DRY it
        tagged_well = well
        while transfer_requests=tagged_well.requests.select { |r| r.is_a?(TransferRequest) }  and transfer_requests.size == 1
          target_well = transfer_requests.first.target_asset
          break unless target_well.is_a?(Well)
          tagged_well=target_well
          tag_on_well = tagged_well.primary_aliquot.try(:tag)
          if tag_on_well.present?
            tag_name              = tag_on_well.name
            tag_expected_sequence = tag_on_well.oligo
            tag_group_name        = tag_on_well.tag_group.name if tag_on_well.tag_group.present?
            break
          end
        end

        sample = well.primary_aliquot.try(:sample)
        csv << [
          well.plate.sanger_human_barcode,
          well.map.description,
          well.study.try(:name),
          request.target_asset.try(:barcode),
          tag_group_name,
          tag_name,
          tag_expected_sequence,
          sample.sanger_sample_id || sample.name,
          well.parent.well_attribute.measured_volume,
          well.parent.well_attribute.concentration
        ]
      end
    end

    report_data
  end

  def pulldown_report_headers
    ['Plate', 'Well', 'Study','Pooled Tube', 'Tag Group', 'Tag', 'Expected Sequence', 'Sample Name', 'Measured Volume', 'Measured Concentration']
  end

  def show_actions?
    self.released? == false or
      self.pipeline.class.const_get(:ALWAYS_SHOW_RELEASE_ACTIONS)
  end

  def npg_set_state
    complete = true
    self.requests.each do |request|
      unless request.asset.is_a_resource
        event = request.events.family_pass_and_fail.first
        if (event.nil?)
          complete = false
        end
      end
    end

    if complete
     self.state = "released"
     self.qc_complete
     self.save!
    end
  end

  def show_fail_link?
    self.released? && self.pipeline.sequencing?
  end
end
