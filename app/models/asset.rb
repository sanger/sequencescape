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
  include Event::PlateEvents
  extend EventfulRecord

  AssetRefactor.when_refactored do
    self.abstract_class = true
  end

  class_attribute :stock_message_template, instance_writer: false
  # The partial used to render the list of assets on the asset show page
  class_attribute :sample_partial, instance_writer: false
  # When set to true, allows assets of this type to be automatically moved
  # from the asset_group show page
  class_attribute :automatic_move, instance_writer: false
  # Determines if the user is presented with the request additional sequencing link
  class_attribute :sequenceable, instance_writer: false

  self.per_page = 500
  self.inheritance_column = 'sti_type'
  self.sample_partial = 'assets/samples_partials/blank'
  self.automatic_move = false
  self.sequenceable = false

  # Receptacle based associations
  # This block is disabled when we have the labware table present as part of the AssetRefactor
  # Ie. This is what will happens now
  AssetRefactor.when_not_refactored do
    include ReceptacleAssociations
    include LabwareAssociations
    include Uuid::Uuidable
    include AssetLink::Associations
    include Commentable
    has_many :messengers, as: :target, inverse_of: :target
  end

  delegate :human_barcode, to: :labware, prefix: true, allow_nil: true

  has_many_events do
    event_constructor(:create_external_release!,       ExternalReleaseEvent,          :create_for_asset!)
    event_constructor(:create_state_update!,           Event::AssetSetQcStateEvent,   :create_updated!)
    event_constructor(:create_scanned_into_lab!,       Event::ScannedIntoLabEvent,    :create_for_asset!)
    event_constructor(:create_plate!,                  Event::PlateCreationEvent,     :create_for_asset!)
    event_constructor(:create_gel_qc!,                 Event::SampleLogisticsQcEvent, :create_gel_qc_for_asset!)
    event_constructor(:created_using_sample_manifest!, Event::SampleManifestEvent,    :created_sample!)
    event_constructor(:updated_using_sample_manifest!, Event::SampleManifestEvent,    :updated_sample!)
    event_constructor(:updated_fluidigm_plate!,        Event::SequenomLoading,        :updated_fluidigm_plate!)
    event_constructor(:update_gender_markers!,         Event::SequenomLoading,        :created_update_gender_makers!)
    event_constructor(:update_sequenom_count!,         Event::SequenomLoading,        :created_update_sequenom_count!)
  end
  has_many_lab_events

  has_one_event_with_family 'scanned_into_lab'

  delegate :last_qc_result_for, to: :qc_results

  broadcast_via_warren

  scope :include_requests_as_target, -> { includes(:requests_as_target) }
  scope :include_requests_as_source, -> { includes(:requests_as_source) }

  scope :sorted, ->() { order('map_id ASC') }
  scope :for_summary, -> { includes(:map, :barcodes) }

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

  # Very much a Labware method
  class << self
    def find_from_any_barcode(source_barcode)
      if source_barcode.blank?
        nil
      elsif /\A[0-9]{1,7}\z/.match?(source_barcode) # Just a number
        joins(:barcodes).where('barcodes.barcode LIKE "__?_"', source_barcode).first # rubocop:disable Rails/FindBy
      else
        find_by_barcode(source_barcode)
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

  def role
    stock_plate&.stock_role
  end

  # Assigns name
  # @note Overridden on subclasses to append the asset id to the name
  #       via on_create callbacks
  def generate_name(new_name)
    self.name = new_name
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

  def assign_relationships(parents, child)
    parents.each do |parent|
      parent.children.delete(child)
      AssetLink.create_edge(parent, self)
    end
    AssetLink.create_edge(self, child)
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
    class_name = self.class.name
    raise StandardError, "No stock template configured for #{class_name}. If #{class_name} is a stock, set stock_template on the class." if stock_message_template.nil?

    Messenger.create!(target: self, template: stock_message_template, root: 'stock_resource')
  end

  def update_from_qc(qc_result)
    Rails.logger.info "#{self.class.name} #{id} updated by QcResult #{qc_result.id}"
  end

  def get_qc_result_value_for(key)
    last_qc_result_for(key).pluck(:value).first
  end
end
