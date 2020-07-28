# frozen_string_literal: true

# Labware represents a physical object which moves around the lab.
# It has one or more receptacles.
class Labware < Asset
  include LabwareAssociations
  include Commentable
  include Uuid::Uuidable
  include AssetLink::Associations
  include SharedBehaviour::Named

  attr_reader :storage_location_service

  delegate :metadata, to: :custom_metadatum_collection, allow_nil: true

  class_attribute :receptacle_class
  self.receptacle_class = 'Receptacle'
  self.sample_partial = 'assets/samples_partials/asset_samples'

  has_many :receptacles, dependent: :restrict_with_exception
  has_many :messengers, as: :target, inverse_of: :target, dependent: :destroy
  has_many :aliquots, through: :receptacles
  has_many :samples, through: :receptacles
  has_many :studies, -> { distinct }, through: :receptacles
  has_many :projects, -> { distinct }, through: :receptacles
  has_many :requests_as_source, through: :receptacles
  has_many :requests_as_target, through: :receptacles
  has_many :transfer_requests_as_source, through: :receptacles
  has_many :transfer_requests_as_target, through: :receptacles
  has_many :submissions, through: :receptacles
  has_many :asset_groups, through: :receptacles
  has_many :creation_batches, class_name: 'Batch', through: :requests_as_target, source: :batch

  belongs_to :purpose, foreign_key: :plate_purpose_id, optional: true, inverse_of: :labware
  has_one :spiked_in_buffer_links, -> { joins(:ancestor).where(labware: { sti_type: 'SpikedBuffer' }).direct },
          class_name: 'AssetLink', foreign_key: :descendant_id, inverse_of: :descendant
  has_one :spiked_in_buffer, through: :spiked_in_buffer_links, source: :ancestor
  has_many :asset_audits, foreign_key: :asset_id, dependent: :destroy, inverse_of: :asset
  has_many :volume_updates, foreign_key: :target_id, dependent: :destroy, inverse_of: :target
  has_many :state_changes, foreign_key: :target_id, dependent: :destroy, inverse_of: :target
  has_one :custom_metadatum_collection, foreign_key: :asset_id, dependent: :destroy, inverse_of: :asset
  belongs_to :labware_type, class_name: 'PlateType', optional: true

  scope :with_required_aliquots, ->(aliquots_ids) { joins(:aliquots).where(aliquots: { id: aliquots_ids }) }
  scope :for_search_query, lambda { |query|
    where('labware.name LIKE :name', name: "%#{query}%")
      .or(with_safe_id(query))
      .includes(:barcodes)
  }
  scope :for_lab_searches_display, -> { includes(:barcodes, requests_as_source: %i[pipeline batch]).order('requests.pipeline_id ASC') }
  scope :named, ->(name) { where(name: name) }
  scope :with_purpose, ->(*purposes) { where(plate_purpose_id: purposes.flatten) }
  scope :include_scanned_into_lab_event, -> { includes(:scanned_into_lab_event) }
  scope :include_creation_batches, -> { includes(:creation_batches) }

  def human_barcode
    'UNKNOWN'
  end

  # Assigns name
  # @note Overridden on subclasses to append the asset id to the name
  #       via on_create callbacks
  def generate_name(new_name)
    self.name = new_name
  end

  def display_name
    name.presence || "#{sti_type} #{id}"
  end

  def labwhere_location
    @labwhere_location ||= lookup_labwhere_location
  end

  # Labware reflects the physical piece of plastic corresponding to an asset
  def labware
    self
  end

  def storage_location
    @storage_location ||= obtain_storage_location
  end

  def scanned_in_date
    scanned_into_lab_event.try(:content) || ''
  end

  # Bulk retrieves locations for multiple labwares at once
  # Returns hash { labware barcode => location string, .. } e.g. { 'DN1234' => 'Sanger - Room 1 - Shelf 2' }
  # Hash has blank values where location was not found for a particular barcode
  # Or raises LabWhereClient::LabwhereException if Labwhere response is unexpected
  def self.labwhere_locations(labware_barcodes)
    info_from_labwhere = LabWhereClient::LabwareSearch.find_locations_by_barcodes(labware_barcodes)

    raise LabWhereClient::LabwhereException, 'Labwhere service did not return information' if info_from_labwhere.blank?

    barcodes_to_parentage = info_from_labwhere.labwares.each_with_object({}) do |info, obj|
      obj[info.barcode] = info.location.location_info
    end

    unless labware_barcodes.count == barcodes_to_parentage.count
      labware_barcodes.each do |barcode|
        # add missing barcodes to the hash, with an empty string for location, for ones that Labwhere didn't return
        barcodes_to_parentage[barcode] ||= ''
      end
    end
    barcodes_to_parentage
  end

  private

  def obtain_storage_location
    if labwhere_location.present?
      @storage_location_service = 'LabWhere'
      labwhere_location
    else
      @storage_location_service = 'None'
      'LabWhere location not set. Could this be in ETS?'
    end
  end

  def lookup_labwhere_location
    lookup_labwhere(machine_barcode) || lookup_labwhere(human_barcode)
  end

  def lookup_labwhere(barcode)
    begin
      info_from_labwhere = LabWhereClient::Labware.find_by_barcode(barcode)
    rescue LabWhereClient::LabwhereException => e
      return "Not found (#{e.message})"
    end
    return info_from_labwhere.location.location_info if info_from_labwhere.present? && info_from_labwhere.location.present?
  end
end
