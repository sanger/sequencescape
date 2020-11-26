# frozen_string_literal: true

# Labware represents a physical object which moves around the lab.
# It has one or more receptacles.
class Labware < Asset
  include Commentable
  include Uuid::Uuidable
  include AssetLink::Associations
  include SharedBehaviour::Named

  attr_reader :storage_location_service

  delegate :metadata, to: :custom_metadatum_collection, allow_nil: true

  class_attribute :receptacle_class
  self.receptacle_class = 'Receptacle'
  self.sample_partial = 'assets/samples_partials/asset_samples'

  has_many :barcodes, foreign_key: :asset_id, inverse_of: :asset, dependent: :destroy
  has_many :receptacles, dependent: :restrict_with_exception
  has_many :messengers, as: :target, inverse_of: :target, dependent: :destroy

  # The following are all through receptacles
  has_many :aliquots, through: :receptacles
  has_many :samples, through: :receptacles
  has_many :studies, -> { distinct }, through: :receptacles
  has_many :projects, -> { distinct }, through: :receptacles
  has_many :requests_as_source, through: :receptacles
  has_many :requests_as_target, through: :receptacles
  has_many :transfer_requests_as_source, through: :receptacles
  has_many :transfer_requests_as_target, through: :receptacles

  # Submissions in progress for the labware. Found by looking at those associated
  # with the transfer requests into the receptacles. Be a little cautious using this,
  # as it will not handle cross-submission pools, but is better for historical
  # data.
  has_many :submissions, through: :receptacles

  # Direct submissions are those made on the plate itself, and are found via
  # the orders associated with the well.s
  has_many :direct_submissions, -> { distinct }, through: :receptacles
  has_many :asset_groups, through: :receptacles

  # The requests which were being processed to make the plate/tube
  # This should probably be switched to going through aliquots, but not 100% certain that it wont cause side effects
  # Might just be safer to wait until we've moved off onto the new api
  has_many :in_progress_submissions, -> { distinct }, through: :transfer_requests_as_target, source: :submission

  has_many :contained_samples, through: :receptacles, source: :samples
  has_many :contained_aliquots, through: :receptacles, source: :aliquots

  has_many :in_progress_requests, through: :contained_aliquots, source: :request

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

  has_many :batches_as_source, -> { distinct }, through: :requests_as_source, source: :batch

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

  # We accept not only an individual barcode but also an array of them.
  scope :with_barcode, lambda { |*barcodes|
    db_barcodes = Barcode.extract_barcodes(barcodes)
    joins(:barcodes).where(barcodes: { barcode: db_barcodes }).distinct
  }
  # In contrast to with_barocde, filter_by_barcode only filters in the event
  # a parameter is supplied. eg. an empty string does not filter the data
  scope :filter_by_barcode, lambda { |*barcodes|
    db_barcodes = Barcode.extract_barcodes(barcodes)
    db_barcodes.blank? ? includes(:barcodes) : includes(:barcodes).where(barcodes: { barcode: db_barcodes }).distinct
  }

  scope :source_assets_from_machine_barcode, lambda { |destination_barcode|
    destination_asset = find_by_barcode(destination_barcode)
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

  # Class methods
  class << self
    # Bulk retrieves locations for multiple labwares at once
    # Returns hash { labware barcode => location string, .. } e.g. { 'DN1234' => 'Sanger - Room 1 - Shelf 2' }
    # Hash has blank values where location was not found for a particular barcode
    # Or raises LabWhereClient::LabwhereException if Labwhere response is unexpected
    def labwhere_locations(labware_barcodes)
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

  def parent
    parents.first
  end

  def child
    children.last
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
