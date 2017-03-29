# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2007-2011,2012,2013,2014,2015,2016 Genome Research Ltd.

class PlatePurpose < Purpose
  module Associations
    def self.included(base)
      base.class_eval do
        # TODO: change to purpose_id
        belongs_to :plate_purpose, foreign_key: :plate_purpose_id
        belongs_to :purpose, foreign_key: :plate_purpose_id
        scope :with_plate_purpose, ->(*purposes) {
          where(plate_purpose_id: purposes.flatten)
        }
      end
    end

    # Delegate the change of state to our plate purpose.
    def transition_to(state, user, contents = nil, customer_accepts_responsibility = false)
      purpose.transition_to(self, state, user, contents, customer_accepts_responsibility)
    end

    # Delegate the transfer request type determination to our plate purpose
    def transfer_request_type_from(source)
      purpose.transfer_request_type_from(source.plate_purpose)
    end
  end

  include Relationship::Associations

  scope :compatible_with_purpose, ->(purpose) {
    if purpose.nil?
      none
    else
      where(target_type: purpose.target_type).order(name: :asc)
    end
  }

  scope :cherrypickable_as_target, -> { where(cherrypickable_target: true) }
  scope :cherrypickable_as_source, -> { where(cherrypickable_source: true) }
  scope :cherrypickable_default_type, -> { where(cherrypickable_target: true, cherrypickable_source: true) }
  scope :for_submissions, ->() do
    where('stock_plate = true OR name = "Working Dilution"')
      .order(stock_plate: :desc)
  end
  scope :considered_stock_plate, -> { where(stock_plate: true) }

  serialize :cherrypick_filters
  validates_presence_of(:cherrypick_filters, if: :cherrypickable_target?)
  before_validation(if: :cherrypickable_target?) do |r|
    r[:cherrypick_filters] ||= ['Cherrypick::Strategy::Filter::ShortenPlexesToFit']
  end

  before_validation :set_default_target_type

  belongs_to :asset_shape

  def source_plate(plate)
    source_purpose_id.present? ? plate.ancestor_of_purpose(source_purpose_id) : plate.stock_plate
  end
  alias_method :library_source_plate, :source_plate

  def source_plates(plate)
    source_purpose_id.present? ? plate.ancestors_of_purpose(source_purpose_id) : [plate.stock_plate]
  end
  alias_method :library_source_plates, :source_plates

  def cherrypick_strategy
    Cherrypick::Strategy.new(self)
  end

  def cherrypick_dimension
    cherrypick_direction == 'column' ? plate_height : plate_width
  end

  def cherrypick_completed(plate)
    messenger_creators.each { |creator| creator.create!(plate) }
  end

  def plate_height
    asset_shape.plate_height(size)
  end

  def plate_width
    asset_shape.plate_width(size)
  end

  def cherrypick_filters
    self[:cherrypick_filters].map(&:constantize)
  end

  # The state of a plate is based on the transfer requests.
  def state_of(plate)
    plate.state_from(plate.transfer_requests)
  end

  # Updates the state of the specified plate to the specified state.  The basic implementation does this by updating
  # all of the TransferRequest instances to the state specified.  If contents is blank then the change is assumed to
  # relate to all wells of the plate, otherwise only the selected ones are updated.
  def transition_to(plate, state, _user, contents = nil, customer_accepts_responsibility = false)
    wells = plate.wells
    wells = wells.located_at(contents) unless contents.blank?

    transition_state_requests(wells, state)
    fail_stock_well_requests(wells, customer_accepts_responsibility) if state == 'failed'
  end

  # Set the class to PlatePurpose::Input is set to true.
  # Allows creation of the input plate purposes through the API
  # without directly exposing our class names.
  #
  # @param [Bool] is_input Set to true to assign the sti type to PlatePurpose::Input
  def input_plate=(is_input)
    self.type = 'PlatePurpose::Input' if is_input
  end

  module Overrideable
    def transition_state_requests(wells, state)
      wells = wells.includes(requests_as_target: { asset: :aliquots, target_asset: :aliquots })
      wells.each { |w| w.requests_as_target.each { |r| r.transition_to(state) } }
    end
    private :transition_state_requests

    # Override this method to control the requests that should be failed for the given wells.
    def fail_request_details_for(wells)
      wells.each do |well|
        submission_ids = well.requests_as_target.map(&:submission_id)
        next if submission_ids.empty?

        stock_wells = well.stock_wells.map(&:id)
        next if stock_wells.empty?

        yield(submission_ids, stock_wells)
      end
    end
    private :fail_request_details_for
  end

  include Overrideable

  def fail_stock_well_requests(wells, customer_accepts_responsibility)
    # Load all of the requests that come from the stock wells that should be failed.  Note that we can't simply change
    # their state, we have to actually use the statemachine method to do this to get the correct behaviour.
    conditions, parameters = [], []
    fail_request_details_for(wells) do |submission_ids, stock_wells|
      # Efficiency gain to be had using '=' over 'IN' when there is only one value to consider.
      condition, args = [], []
      condition[0], args[0] = (submission_ids.size == 1) ? ['submission_id=?', submission_ids.first] : ['submission_id IN (?)', submission_ids]
      condition[1], args[1] = (stock_wells.size == 1)    ? ['asset_id=?', stock_wells.first] : ['asset_id IN (?)', stock_wells]
      conditions << "(#{condition[0]} AND #{condition[1]})"
      parameters.concat(args)
    end
    raise 'Apparently there are not requests on these wells?' if conditions.empty?
    Request.where_is_not_a?(TransferRequest).where(["(#{conditions.join(' OR ')})", *parameters]).map do |request|
      # This can probably be switched for an each, as I don't think the array is actually used for anything.
      request.request_metadata.update_attributes!(customer_accepts_responsibility: true) if customer_accepts_responsibility
      request.passed? ? request.retrospective_fail! : request.fail!
    end
  end
  private :fail_stock_well_requests

  def pool_wells(wells)
    _pool_wells(wells)
      .joins('LEFT OUTER JOIN uuids AS pool_uuids ON pool_uuids.resource_type="Submission" AND pool_uuids.resource_id=submission_id')
      .select('pool_uuids.external_id AS pool_uuid')
      .readonly(false)
      .tap do |wells_with_pool|
        raise StandardError, 'Cannot deal with a well in multiple pools' if wells_with_pool.group_by(&:id).any? { |_, multiple_pools| multiple_pools.uniq.size > 1 }
      end
  end

  def _pool_wells(wells)
    wells.pooled_as_target_by(TransferRequest)
  end
  private :_pool_wells

  include Api::PlatePurposeIO::Extensions

  self.per_page = 500

  # TODO: change to purpose_id
  has_many :plates, foreign_key: :plate_purpose_id

  def self.stock_plate_purpose
    # IDs copied from SNP
    PlatePurpose.find(2)
  end

  def size
    attributes['size'] || 96
  end

  def well_locations
    in_preferred_order(Map.where_plate_size(size).where_plate_shape(asset_shape))
  end

  def in_preferred_order(relationship)
    relationship.send("in_#{cherrypick_direction}_major_order")
  end

  def create!(*args, &block)
    attributes          = args.extract_options!
    do_not_create_wells = args.first.present?
    attributes[:size]     ||= size
    attributes[:location] ||= default_location
    attributes[:purpose] = self
    pla = target_class.create_with_barcode!(attributes, &block).tap do |plate|
      plate.wells.construct! unless do_not_create_wells
    end
  end

  def cherrypick_in_rows?
    cherrypick_direction == 'row'
  end

  def attatched?(_plate)
    true
  end

  def child_plate_purposes
    child_purposes.where_is_a?(PlatePurpose)
  end

  def source_wells_for(stock_wells)
    stock_wells
  end

  def supports_multiple_submissions?
    false
  end

  private

  def set_default_target_type
    self.target_type ||= 'Plate'
  end
end

# Ensure rails eager loading behaves as intended
# We should consider renaming our classes to make this easier to maintain
require_dependency 'dilution_plate_purpose'
require_dependency 'plate_purpose/input'
require_dependency 'qcable_library_plate_purpose'
require_dependency 'qcable_plate_purpose'
require_dependency 'illumina_c/al_libs_tagged_purpose'
require_dependency 'illumina_c/lib_pcr_purpose'
require_dependency 'illumina_c/lib_pcr_xp_purpose'
require_dependency 'illumina_c/stock_purpose'
require_dependency 'illumina_htp/downstream_plate_purpose'
require_dependency 'illumina_htp/final_plate_purpose'
require_dependency 'illumina_htp/library_complete_on_qc_purpose'
require_dependency 'illumina_htp/normalized_plate_purpose'
require_dependency 'illumina_htp/pooled_plate_purpose'
require_dependency 'illumina_htp/post_shear_qc_plate_purpose'
require_dependency 'plate_purpose/initial_purpose'
require_dependency 'pulldown/initial_plate_purpose'
require_dependency 'pulldown/library_plate_purpose'
