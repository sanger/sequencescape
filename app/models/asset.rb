require 'eventful_record'

# Asset is a very busy class which combines what should probably be two separate concepts:
# Labware: A physical item which can move round the lab, such as a {Plate} or {Tube}
#
# Key subclasses
# --------------
# - {Receptacle}: Something which can contain aliquots, such as a {Well} or {Tube}
#   Currently those these all share a table, and exhibit single table inheritance.
# - {Plate}: A piece of labware containing multiple receptacles known as {Well wells}.
#   Plates can be a variety of shapes and sizes, although the marority are 12*8 (96) or
#   24*16 (384) wells in size.
# - {Well}: A receptacle on a plate. Wells themselves do not exist independently of plates in reality,
#   although may occasionally be modelled as such.
# - {Tube}: A piece of labware with a single {Receptacle}. These behaviours are currently coupled together.
# - {Lane}: Forms part of a sequencing Flowcell. The flowcell itself is not currently modelled but can be
#   approximated by a {Batch}
# - {Fragment}: Represents an isolated segment of DNA on a Gel. Historical.
# - {Receptacle}: Abstract class inherited by any asset which can contain stuff directly
#
# Some of the above are further subclasses to handle specific behaviours.
class Asset < ApplicationRecord
  include Api::Messages::QcResultIO::AssetExtensions
  include Uuid::Uuidable
  include Commentable
  include Event::PlateEvents
  include AssetLink::Associations

  class_attribute :stock_message_template, instance_writer: false
  # The partial used to render the list of assets on the asset show page
  class_attribute :sample_partial, instance_writer: false
  # When set to true, allows assets of this type to be automatically moved
  # from the asset_group show page
  class_attribute :automatic_move, instance_writer: false
  # Set to true on the products of library creation. Controls name generation.
  class_attribute :library_prep, instance_writer: false
  # Determines if the user is presented with the request additional sequencing link
  class_attribute :sequenceable, instance_writer: false

  class VolumeError < StandardError
  end

  self.per_page = 500
  self.inheritance_column = 'sti_type'
  self.sample_partial = 'assets/samples_partials/blank'
  self.automatic_move = false
  self.library_prep = false
  self.sequenceable = false

  # @note Splitting out these associations now can cause issues with a number of issues with eager loading
  #       so organizing things first while we establish a migration route.

  # Labware based associations
  has_many :barcodes, foreign_key: :asset_id, inverse_of: :asset, dependent: :destroy
  has_many :asset_audits
  has_many :volume_updates, foreign_key: :target_id
  has_many :state_changes, foreign_key: :target_id
  has_one :custom_metadatum_collection
  belongs_to :labware_type, class_name: 'PlateType', optional: true

  # Receptacle based associations
  has_many :asset_group_assets, dependent: :destroy, inverse_of: :asset
  has_many :asset_groups, through: :asset_group_assets
  has_many :qc_results, dependent: :destroy
  # TODO: Remove 'requests' and 'source_request' as they are abiguous
  # :requests should go before :events_on_requests, through: :requests
  belongs_to :map
  has_many :requests
  has_many :events_on_requests, through: :requests, source: :events, validate: false
  has_one  :source_request,     ->() { includes(:request_metadata) }, class_name: 'Request', foreign_key: :target_asset_id
  has_many :requests_as_source, ->() { includes(:request_metadata) },  class_name: 'Request', foreign_key: :asset_id
  has_many :requests_as_target, ->() { includes(:request_metadata) },  class_name: 'Request', foreign_key: :target_asset_id
  has_one :creation_request, class_name: 'Request', foreign_key: :target_asset_id
  has_many :sample_manifest_assets
  has_many :sample_manifests, through: :sample_manifest_assets

  # Polymorphic associations
  has_many :messengers, as: :target, inverse_of: :target

  delegate :human_barcode, to: :labware, prefix: true, allow_nil: true

  extend EventfulRecord
  has_many_events do
    event_constructor(:create_external_release!,       ExternalReleaseEvent,          :create_for_asset!)
    event_constructor(:create_pass!,                   Event::AssetSetQcStateEvent,   :create_updated!)
    event_constructor(:create_fail!,                   Event::AssetSetQcStateEvent,   :create_updated!)
    event_constructor(:create_state_update!,           Event::AssetSetQcStateEvent,   :create_updated!)
    event_constructor(:create_scanned_into_lab!,       Event::ScannedIntoLabEvent,    :create_for_asset!)
    event_constructor(:create_plate!,                  Event::PlateCreationEvent,     :create_for_asset!)
    event_constructor(:create_plate_with_date!,        Event::PlateCreationEvent,     :create_for_asset_with_date!)
    event_constructor(:create_gel_qc!,                 Event::SampleLogisticsQcEvent, :create_gel_qc_for_asset!)
    event_constructor(:created_using_sample_manifest!, Event::SampleManifestEvent,    :created_sample!)
    event_constructor(:updated_using_sample_manifest!, Event::SampleManifestEvent,    :updated_sample!)
    event_constructor(:updated_fluidigm_plate!,        Event::SequenomLoading,        :updated_fluidigm_plate!)
    event_constructor(:update_gender_markers!,         Event::SequenomLoading,        :created_update_gender_makers!)
    event_constructor(:update_sequenom_count!,         Event::SequenomLoading,        :created_update_sequenom_count!)
  end
  has_many_lab_events

  has_one_event_with_family 'scanned_into_lab'
  has_one_event_with_family 'moved_to_2d_tube'

  delegate :metadata, to: :custom_metadatum_collection, allow_nil: true

  delegate :last_qc_result_for, to: :qc_results

  broadcast_via_warren

  after_create :generate_name_with_id, if: :name_needs_to_be_generated?

  scope :include_requests_as_target, -> { includes(:requests_as_target) }
  scope :include_requests_as_source, -> { includes(:requests_as_source) }

  scope :sorted, ->() { order('map_id ASC') }
  scope :for_summary, -> { includes(:map, :barcodes) }

  scope :of_type, ->(*args) { where(sti_type: args.map { |t| [t, *t.descendants] }.flatten.map(&:name)) }

  scope :recent_first, -> { order(id: :desc) }

  scope :include_for_show, -> { includes({ requests: [:request_type, :request_metadata] }, requests_as_target: [:request_type, :request_metadata]) }

  # The use of a sub-query here is a performance optimization. If we join onto the asset_links
  # table instead, rails is unable to paginate the results efficiently, as it needs to use DISTINCT
  # when working out offsets. This is substantially slower.
  scope :without_children, -> { where.not(id: AssetLink.where(direct: true).select(:ancestor_id)) }
  scope :include_plates_with_children, ->(filter) { filter ? all : without_children }

  # Named scope for search by query string behaviour
  scope :for_search_query, ->(query) {
    where.not(sti_type: 'Well').where('assets.name LIKE :name', name: "%#{query}%").includes(:barcodes)
         .or(where.not(sti_type: 'Well').with_safe_id(query).includes(:barcodes))
  }

  scope :for_lab_searches_display, -> { includes(:barcodes, requests: [:pipeline, :batch]).order('requests.pipeline_id ASC') }

  # We accept not only an individual barcode but also an array of them.
  scope :with_barcode, ->(*barcodes) {
    db_barcodes = Barcode.extract_barcodes(barcodes)
    joins(:barcodes).where(barcodes: { barcode: db_barcodes }).distinct
  }

  # In contrast to with_barocde, filter_by_barcode only filters in the event
  # a parameter is supplied. eg. an empty string does not filter the data
  scope :filter_by_barcode, ->(*barcodes) {
    db_barcodes = Barcode.extract_barcodes(barcodes)
    db_barcodes.blank? ? includes(:barcodes) : includes(:barcodes).where(barcodes: { barcode: db_barcodes }).distinct
  }

  scope :source_assets_from_machine_barcode, ->(destination_barcode) {
    destination_asset = find_from_barcode(destination_barcode)
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

  class << self
    def find_from_any_barcode(source_barcode)
      if source_barcode.blank?
        nil
      elsif /\A[0-9]{1,7}\z/.match?(source_barcode) # Just a number
        joins(:barcodes).where('barcodes.barcode LIKE "__?_"', source_barcode).first # rubocop:disable Rails/FindBy
      else
        find_from_barcode(source_barcode)
      end
    end

    def find_by_barcode(source_barcode)
      with_barcode(source_barcode).first
    end
    alias find_from_barcode find_by_barcode
  end

  def summary_hash
    {
      asset_id: id
    }
  end

  # Returns the type of asset that can be considered appropriate for request types.
  def asset_type_for_request_types
    self.class
  end

  def tube_name
    (primary_aliquot.nil? or primary_aliquot.sample.sanger_sample_id.blank?) ? name : primary_aliquot.sample.shorten_sanger_sample_id
  end

  def ancestor_of_purpose(_ancestor_purpose_id)
    # If it's not a tube or a plate, defaults to stock_plate
    stock_plate
  end

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

  def role
    stock_plate&.stock_role
  end

  def generate_name_with_id
    update!(name: "#{name} #{id}")
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

  def display_name
    name.presence || "#{sti_type} #{id}"
  end

  def external_identifier
    "#{sti_type}#{id}"
  end

  def details
    nil
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

  def assign_relationships(parents, child)
    parents.each do |parent|
      parent.children.delete(child)
      AssetLink.create_edge(parent, self)
    end
    AssetLink.create_edge(self, child)
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

  def original_stock_plates
    ancestors.where(plate_purpose_id: PlatePurpose.stock_plate_purpose)
  end

  def spiked_in_buffer
    nil
  end

  def has_stock_asset?
    false
  end

  def compatible_purposes
    Purpose.none
  end

  # Most assets don't have a barcode
  def barcode_number
    nil
  end

  def prefix
    nil
  end

  # By default only barcodeable assets generate barcodes
  def generate_barcode
    nil
  end

  # Returns nil because assets really don't have barcodes!
  def barcode_type
    nil
  end

  # We only support wells for the time being
  def latest_stock_metrics(_product, *_args)
    []
  end

  def contained_samples
    Sample.none
  end

  def source_plate
    nil
  end

  def printable?
    printable_target.present?
  end

  def printable_target
    nil
  end

  # Generates a message to broadcast the tube to the stock warehouse
  # tables. Raises an exception if no template is configured for a give
  # asset. In most cases this is because the asset is not a stock
  def register_stock!
    raise StandardError, "No stock template configured for #{self.class.name}. If #{self.class.name} is a stock, set stock_template on the class." if stock_message_template.nil?

    Messenger.create!(target: self, template: stock_message_template, root: 'stock_resource')
  end

  def update_from_qc(qc_result)
    Rails.logger.info "#{self.class.name} #{id} updated by QcResult #{qc_result.id}"
  end

  def get_qc_result_value_for(key)
    last_qc_result_for(key).pluck(:value).first
  end

  private

  def update_external_release
    external_release_nil_before = external_release.nil?
    yield
    save!
    events.create_external_release!(!external_release_nil_before) unless external_release.nil?
  end

  def name_needs_to_be_generated?
    instance_variable_defined?(:@name_needs_to_be_generated) && @name_needs_to_be_generated
  end
end
