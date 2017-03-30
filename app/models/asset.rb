# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2007-2011,2012,2013,2014,2015,2016 Genome Research Ltd.

require 'eventful_record'
require 'external_properties'

require 'eventful_record'
require 'external_properties'

class Asset < ActiveRecord::Base
  include StudyReport::AssetDetails
  include ModelExtensions::Asset
  include AssetLink::Associations
  include SharedBehaviour::Named

  SAMPLE_PARTIAL = 'assets/samples_partials/blank'

  module InstanceMethods
    # Assets are, by default, non-barcoded
    def generate_barcode
      # Does nothing!
    end

    # Returns nil because assets really don't have barcodes!
    def barcode_type
      nil
    end
  end
  include InstanceMethods

  class VolumeError < StandardError
  end

  def summary_hash
    {
      asset_id: id
    }
  end

  def sample_partial
    self.class::SAMPLE_PARTIAL
  end

  self.per_page = 500
  self.inheritance_column = 'sti_type'

  has_many :asset_group_assets, dependent: :destroy, inverse_of: :asset
  has_many :asset_groups, through: :asset_group_assets
  has_many :asset_audits
  has_many :volume_updates, foreign_key: :target_id
  has_many :events_on_requests, through: :requests, source: :events

  # TODO: Remove 'requests' and 'source_request' as they are abiguous
  has_many :requests
  has_one  :source_request,     ->() { includes(:request_metadata) }, class_name: 'Request', foreign_key: :target_asset_id
  has_many :requests_as_source, ->() { includes(:request_metadata) },  class_name: 'Request', foreign_key: :asset_id
  has_many :requests_as_target, ->() { includes(:request_metadata) },  class_name: 'Request', foreign_key: :target_asset_id
  has_many :state_changes, foreign_key: :target_id

  scope :include_requests_as_target, -> { includes(:requests_as_target) }
  scope :include_requests_as_source, -> { includes(:requests_as_source) }

  scope :where_is_a?,     ->(clazz) { where(sti_type: [clazz, *clazz.descendants].map(&:name)) }
  scope :where_is_not_a?, ->(clazz) { where(['sti_type NOT IN (?)', [clazz, *clazz.descendants].map(&:name)]) }

  # Orders
  has_many :submitted_assets
  has_many :orders, through: :submitted_assets

  has_one :custom_metadatum_collection
  delegate :metadata, to: :custom_metadatum_collection

  scope :requests_as_source_is_a?, ->(t) { joins(:requests_as_source).where(requests: { sti_type: [t, *t.descendants].map(&:name) }) }

  # to override in subclass
  def location
    nil
  end

  belongs_to :map
  belongs_to :barcode_prefix
  scope :sorted, ->() { order('map_id ASC') }

  scope :position_name, ->(*args) {
    joins(:map).where(['description = ? AND asset_size = ?', args[0], args[1]])
  }
  scope :for_summary, -> { includes([:map, :barcode_prefix]) }

  scope :of_type, ->(*args) { where(sti_type: args.map { |t| [t, *t.descendants] }.flatten.map(&:name)) }

  scope :recent_first, -> { order('id DESC') }

  scope :include_for_show, ->() { includes(requests: :request_metadata) }

  def studies
    []
  end

  def barcode_and_created_at_hash
    return {} if barcode.blank?
    {
      barcode: generate_machine_barcode,
      created_at: created_at
    }
  end

  def study_ids
    []
  end

  # All studies related to this asset
  def related_studies
    (orders.map(&:study) + studies).compact.uniq
  end
 # Named scope for search by query string behaviour
 scope :for_search_query, ->(query, with_includes) {
    search = '(assets.sti_type != "Well") AND ((assets.name IS NOT NULL AND assets.name LIKE :name)'
    arguments = { name: "%#{query}%" }

    # The entire string consists of one of more numeric characters, treat it as an id or barcode
    if /\A\d+\z/ === query
      search << ' OR (assets.id = :id) OR (assets.barcode = :barcode)'
      arguments[:id] = query.to_i
      arguments[:barcode] = query.to_s
    end

    # If We're a Sanger Human barcode
    if match = /\A([A-z]{2})(\d{1,7})[A-z]{0,1}\z/.match(query)
      prefix_id = BarcodePrefix.find_by(prefix: match[1]).try(:id)
      number = match[2]
      search << ' OR (assets.barcode = :barcode AND assets.barcode_prefix_id = :prefix_id)' unless prefix_id.nil?
      arguments[:barcode] = number
      arguments[:prefix_id] = prefix_id
    end

    search << ')'

    if with_includes
      where(search, arguments)
    else
      where(search, arguments).includes(:requests).order('requests.pipeline_id ASC')
    end
                          }

 scope :with_name, ->(*names) { where(name: names.flatten) }

  extend EventfulRecord
  has_many_events do
    event_constructor(:create_external_release!,       ExternalReleaseEvent,          :create_for_asset!)
    event_constructor(:create_pass!,                   Event::AssetSetQcStateEvent,   :create_updated!)
    event_constructor(:create_fail!,                   Event::AssetSetQcStateEvent,   :create_updated!)
    event_constructor(:create_state_update!,           Event::AssetSetQcStateEvent,   :create_updated!)
    event_constructor(:create_scanned_into_lab!,       Event::ScannedIntoLabEvent,    :create_for_asset!)
    event_constructor(:create_plate!,                  Event::PlateCreationEvent,     :create_for_asset!)
    event_constructor(:create_plate_with_date!,        Event::PlateCreationEvent,     :create_for_asset_with_date!)
    event_constructor(:create_sequenom_stamp!,         Event::PlateCreationEvent,     :create_sequenom_stamp_for_asset!)
    event_constructor(:create_sequenom_plate!,         Event::PlateCreationEvent,     :create_sequenom_plate_for_asset!)
    event_constructor(:create_gel_qc!,                 Event::SampleLogisticsQcEvent, :create_gel_qc_for_asset!)
    event_constructor(:create_pico!,                   Event::SampleLogisticsQcEvent, :create_pico_result_for_asset!)
    event_constructor(:created_using_sample_manifest!, Event::SampleManifestEvent,    :created_sample!)
    event_constructor(:updated_using_sample_manifest!, Event::SampleManifestEvent,    :updated_sample!)
    event_constructor(:updated_fluidigm_plate!, Event::SequenomLoading, :updated_fluidigm_plate!)
    event_constructor(:update_gender_markers!,         Event::SequenomLoading,        :created_update_gender_makers!)
    event_constructor(:update_sequenom_count!,         Event::SequenomLoading,        :created_update_sequenom_count!)
  end
  has_many_lab_events

  has_one_event_with_family 'scanned_into_lab'
  has_one_event_with_family 'moved_to_2d_tube'

  # Key/value stores and attributes
  include ExternalProperties
  acts_as_descriptable :serialized

  include Uuid::Uuidable

  # Links to other databases
  include Identifiable

  include Commentable
  include Event::PlateEvents

  # Returns the request options used to create this asset.  By default assumed to be empty.
  def created_with_request_options
    {}
  end

  def is_sequenceable?
    false
  end

  # Returns the type of asset that can be considered appropriate for request types.
  def asset_type_for_request_types
    self.class
  end

  def tube_name
    (primary_aliquot.nil? or primary_aliquot.sample.sanger_sample_id.blank?) ? name : primary_aliquot.sample.shorten_sanger_sample_id
  end

  def study
    studies.first
  end

  def study_id
    study.try(:id)
  end

  def ancestor_of_purpose(_ancestor_purpose_id)
    # If it's not a tube or a plate, defaults to stock_plate
    stock_plate
  end

  has_one :creation_request, class_name: 'Request', foreign_key: :target_asset_id

  def label
    sti_type || 'Unknown'
  end

  def label=(new_type)
    self.sti_type = new_type
  end

  def request_types
    RequestType.where(asset_type: label)
  end

  def scanned_in_date
    scanned_into_lab_event.try(:content) || ''
  end

  def moved_to_2D_tube_date
    moved_to_2d_tube_event.try(:content) || ''
  end

  def create_asset_group_wells(user, params)
    asset_group = AssetGroup.create(params)
    asset_group.user = user
    asset_group.assets = wells
    asset_group.save!

    # associate sample to study
    if asset_group.study
      wells.each do |well|
        next unless well.sample
        well.sample.studies << asset_group.study
        well.sample.save!
      end
    end

    asset_group
  end

  after_create :generate_name_with_id, if: :name_needs_to_be_generated?

  def name_needs_to_be_generated?
    @name_needs_to_be_generated
  end
  private :name_needs_to_be_generated?

  def generate_name_with_id
    update_attributes!(name: "#{name} #{id}")
  end

  def generate_name(new_name)
    self.name = new_name
    @name_needs_to_be_generated = library_prep?
  end

  # TODO: unify with parent/children
  def parent
    parents.first
  end

  def child
    children.last
  end

  # Labware reflects the physical piece of plastic corresponding to an asset
  def labware
    self
  end

  def library_prep?
    false
  end

  def display_name
    name.blank? ? "#{sti_type} #{id}" : name
  end

  def external_identifier
    "#{sti_type}#{id}"
  end

  def details
    nil
  end

  QC_STATES = [
    ['passed',  'pass'],
    ['failed',  'fail'],
    ['pending', 'pending'],
    [nil, '']
  ]

  QC_STATES.reject { |k, _v| k.nil? }.each do |state, qc_state|
    line = __LINE__ + 1
    class_eval("
      def qc_#{qc_state}
        self.qc_state = #{state.inspect}
        self.save!
      end
    ", __FILE__, line)
  end

  def compatible_qc_state
    QC_STATES.assoc(qc_state).try(:last) || qc_state
  end

  def set_qc_state(state)
    self.qc_state = QC_STATES.rassoc(state).try(:first) || state
    save
    set_external_release(qc_state)
  end

  def has_been_through_qc?
    not qc_state.blank?
  end

  def set_external_release(state)
    update_external_release do
      case
      when state == 'failed'  then self.external_release = false
      when state == 'passed'  then self.external_release = true
      when state == 'pending' then self # Do nothing
      when state.nil?         then self # TODO: Ignore for the moment, correct later
      when ['scanned_into_lab'].include?(state.to_s) then self # TODO: Ignore for the moment, correct later
      else raise StandardError, "Invalid external release state #{state.inspect}"
      end
    end
  end

  def update_external_release
    external_release_nil_before = external_release.nil?
    yield
    save!
    events.create_external_release!(!external_release_nil_before) unless external_release.nil?
  end
  private :update_external_release

  def self.find_by_human_barcode(barcode, location)
    data = Barcode.split_human_barcode(barcode)
    if data[0] == 'DN'
      plate = Plate.find_by(barcode: data[1])
      well = plate.find_well_by_name(location)
      return well if well
    end
    raise ActiveRecord::RecordNotFound, "Couldn't find well with for #{barcode} #{location}"
  end

  def assign_relationships(parents, child)
    parents.each do |parent|
      parent.children.delete(child)
      AssetLink.create_edge(parent, self)
    end
    AssetLink.create_edge(self, child)
  end

 # We accept not only an individual barcode but also an array of them.  This builds an appropriate
 # set of conditions that can find any one of these barcodes.  We map each of the individual barcodes
 # to their appropriate query conditions (as though they operated on their own) and then we join
 # them together with 'OR' to get the overall conditions.
 scope :with_machine_barcode, ->(*barcodes) {
    query_details = barcodes.flatten.map do |source_barcode|
      case source_barcode.to_s
      when /^\d{13}$/ # An EAN13 barcode
        barcode_number = Barcode.number_to_human(source_barcode)
        prefix_string  = Barcode.prefix_from_barcode(source_barcode)
        barcode_prefix = BarcodePrefix.find_by(prefix: prefix_string)

        if barcode_number.nil? or prefix_string.nil? or barcode_prefix.nil?
          { query: 'FALSE' }
        else
          { query: '(barcode=? AND barcode_prefix_id=?)', parameters: [barcode_number, barcode_prefix.id] }
        end
      when /^\d{10}$/ # A Fluidigm barcode
        { joins: 'JOIN plate_metadata AS pmmb ON pmmb.plate_id = assets.id', query: '(pmmb.fluidigm_barcode=?)', parameters: source_barcode.to_s }
      else
        { query: 'FALSE' }
      end
    end.inject(query: ['FALSE'], parameters: [nil], joins: []) do |building, current|
      building.tap do
        building[:joins]      << current[:joins]
        building[:query]      << current[:query]
        building[:parameters] << current[:parameters]
      end
    end

      where([query_details[:query].join(' OR '), *query_details[:parameters].flatten.compact])
        .joins(query_details[:joins].compact.uniq)
                              }

 scope :source_assets_from_machine_barcode, ->(destination_barcode) {
    destination_asset = find_from_machine_barcode(destination_barcode)
    if destination_asset
      source_asset_ids = destination_asset.parents.map(&:id)
      if source_asset_ids.empty?
        none
      else
         where(id: source_asset_ids)
      end
    else
      none
    end
                                            }

  def self.find_from_any_barcode(source_barcode)
    if source_barcode.blank?
      nil
    elsif source_barcode.size == 13 && Barcode.check_EAN(source_barcode)
      with_machine_barcode(source_barcode).first
    elsif match = /\A([A-z]{2})([0-9]{1,7})\w{0,1}\z/.match(source_barcode) # Human Readable
      prefix = BarcodePrefix.find_by(prefix: match[1])
      find_by(barcode: match[2], barcode_prefix_id: prefix.id)
    elsif /\A[0-9]{1,7}\z/ =~ source_barcode # Just a number
      find_by(barcode: source_barcode)
    end
  end

  def self.find_from_machine_barcode(source_barcode)
    with_machine_barcode(source_barcode).first
  end

  def generate_machine_barcode
    (Barcode.calculate_barcode(barcode_prefix.prefix, barcode.to_i)).to_s
  end

  def external_release_text
    return 'Unknown' if external_release.nil?
    external_release? ? 'Yes' : 'No'
  end

  def add_parent(parent)
    return unless parent
    # should be self.parents << parent but that doesn't work

    save!
    parent.save!
    AssetLink.create_edge!(parent, self)
  end

  def attach_tag(tag)
    tag.tag!(self) if tag.present?
  end

  def requests_status(request_type)
    requests.order('id ASC').where(request_type: request_type).pluck(:state)
  end

  def transfer(max_transfer_volume)
    transfer_volume = [max_transfer_volume.to_f, volume || 0.0].min
    raise VolumeError, 'not enough volume left' if transfer_volume <= 0

    self.class.create!(name: name) do |new_asset|
      new_asset.aliquots = aliquots.map(&:dup)
      new_asset.volume   = transfer_volume
      update_attributes!(volume: volume - transfer_volume) #  Update ourselves
    end.tap do |new_asset|
      new_asset.add_parent(self)
    end
  end

  def spiked_in_buffer
    nil
  end

  def has_stock_asset?
    false
  end

  def has_many_requests?
    Request.find_all_target_asset(id).size > 1
  end

  def can_be_created?
    false
  end

  def compatible_purposes
    []
  end

  def automatic_move?
    false
  end

  # See Aliquot::Receptacle for handling of assets with contents
  def tag_count
    nil
  end

  # We only support wells for the time being
  def latest_stock_metrics(_product, *_args)
    []
  end

  def contained_samples; []; end

  def source_plate
    nil
  end

  def printable?
    printable_target.present?
  end

  def printable_target
    nil
  end
end
