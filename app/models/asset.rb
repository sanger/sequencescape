# frozen_string_literal: true
require 'eventful_record'

# Asset is a very busy class which combines what should probably be two separate concepts:
# Labware: A physical item which can move round the lab, such as a {Plate} or {Tube}
#
# This class has now been split into two and should be eliminated.
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
  include Api::Messages::QcResultIo::AssetExtensions
  include Event::PlateEvents
  extend EventfulRecord

  self.abstract_class = true

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

  delegate :human_barcode, to: :labware, prefix: true, allow_nil: true

  has_many_events do
    event_constructor(:create_external_release!, ExternalReleaseEvent, :create_for_asset!)
    event_constructor(:create_state_update!, Event::AssetSetQcStateEvent, :create_updated!)
    event_constructor(:create_scanned_into_lab!, Event::ScannedIntoLabEvent, :create_for_asset!)
    event_constructor(:create_labware_failed!, Event::LabwareFailedEvent, :create_for_asset!)
    event_constructor(:create_plate!, Event::PlateCreationEvent, :create_for_asset!)
    event_constructor(:create_gel_qc!, Event::SampleLogisticsQcEvent, :create_gel_qc_for_asset!)
    event_constructor(:created_using_sample_manifest!, Event::SampleManifestEvent, :created_sample!)
    event_constructor(:updated_using_sample_manifest!, Event::SampleManifestEvent, :updated_sample!)
    event_constructor(:updated_fluidigm_plate!, Event::SequenomLoading, :updated_fluidigm_plate!)
    event_constructor(:update_gender_markers!, Event::SequenomLoading, :created_update_gender_makers!)
    event_constructor(:update_sequenom_count!, Event::SequenomLoading, :created_update_sequenom_count!)
  end
  has_many_lab_events

  has_one_event_with_family 'scanned_into_lab'

  delegate :last_qc_result_for, to: :qc_results

  broadcast_with_warren

  scope :include_requests_as_target, -> { includes(:requests_as_target) }
  scope :include_requests_as_source, -> { includes(:requests_as_source) }

  scope :sorted, -> { order('map_id ASC') }

  scope :recent_first, -> { order(id: :desc) }

  # Includes are mostly handled in the views themselves, which allows us to be
  # a bit more smart about what we load if necessary (Ie. different stuff for plates)
  scope :include_for_show, -> { includes(:studies) }

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

  def details
    nil
  end

  def original_stock_plates
    ancestors.where(plate_purpose_id: PlatePurpose.stock_plate_purpose)
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

  def printable?
    printable_target.present?
  end

  def printable_target
    nil
  end

  def type
    self.class.name.underscore
  end

  # Generates a message to broadcast the tube to the stock warehouse
  # tables. Raises an exception if no template is configured for a give
  # asset. In most cases this is because the asset is not a stock
  # Called when importing samples, e.g. in sample_manifest > core_behaviour, on manifest upload
  def register_stock!
    class_name = self.class.name
    if stock_message_template.nil?
      # rubocop:todo Layout/LineLength
      raise StandardError,
            "No stock template configured for #{class_name}. If #{class_name} is a stock, set stock_template on the class."
      # rubocop:enable Layout/LineLength
    end

    Messenger.create!(target: self, template: stock_message_template, root: 'stock_resource')

  end

  def update_from_qc(qc_result)
    Rails.logger.info "#{self.class.name} #{id} updated by QcResult #{qc_result.id}"
  end

  def get_qc_result_value_for(key)
    last_qc_result_for(key).pick(:value)
  end
end
