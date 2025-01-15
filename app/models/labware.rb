# frozen_string_literal: true

# Labware represents a physical object which moves around the lab.
# It has one or more receptacles.
# rubocop:disable Metrics/ClassLength
class Labware < Asset
  include Commentable
  include Uuid::Uuidable
  include AssetLink::Associations
  include SharedBehaviour::Named

  attr_reader :storage_location_service

  enum :retention_instruction, { destroy_after_2_years: 0, return_to_customer_after_2_years: 1, long_term_storage: 2 }

  delegate :metadata, to: :custom_metadatum_collection, allow_nil: true

  class_attribute :receptacle_class
  self.receptacle_class = 'Receptacle'
  self.sample_partial = 'assets/samples_partials/asset_samples'

  has_many :barcodes, foreign_key: :asset_id, inverse_of: :asset, dependent: :destroy
  has_many :receptacles, dependent: :restrict_with_exception
  has_many :messengers, as: :target, inverse_of: :target, dependent: :destroy

  # The following are all through receptacles
  has_many :aliquots, through: :receptacles do
    # This is mostly to handle legacy code which predates the labware-receptacle split.
    # In many cases we were directly associating aliquots via the association on labware,
    # but rails is not able to handle this with a has_many through. Prior to adding this
    # we used to delegate the aliquots association directs (eg. delegate :aliquots, to: :receptacle)
    # but this messes up eager-loading, especially via the API.
    def receptacle_proxy
      return self unless proxy_association.owner.respond_to?(:receptacle)

      reset # We're about to modify the association indirectly, so any existing records are invalid
      proxy_association.owner.receptacle.aliquots
    end

    delegate :<<, :build, :create, :create!, to: :receptacle_proxy
  end
  has_many :samples, through: :receptacles
  has_many :studies, -> { distinct }, through: :receptacles
  has_many :projects, -> { distinct }, through: :receptacles
  has_many :requests_as_source, through: :receptacles
  has_many :requests_as_target, through: :receptacles
  has_many :transfer_requests_as_source, through: :receptacles
  has_many :transfer_requests_as_target, through: :receptacles

  # @deprecated in_progress_submissions maintains the same behaviour as this,
  # while filtering out duplicate submissions. However, neither this association
  # nor in_progress_submissions handle cross-submission pools
  has_many :submissions, through: :receptacles

  # Direct submissions are those made on the plate itself, and are found via
  # the orders associated with the wells.
  has_many :direct_submissions, -> { distinct }, through: :receptacles
  has_many :asset_groups, through: :receptacles

  # The submissions which were being processed to make the plate/tube, in
  # contrast to direct_submissions, which is work that the plate feeds into.
  # This should probably be switched to going through aliquots, but not 100%
  # certain that it wont cause side effects.
  # History aliquots are currently lacking the request_id
  # Might just be safer to wait until we've moved off onto the new api
  has_many :in_progress_submissions, -> { distinct }, through: :transfer_requests_as_target, source: :submission

  has_many :contained_samples, through: :receptacles, source: :samples
  has_many :contained_aliquots, through: :receptacles, source: :aliquots

  has_many :in_progress_requests, through: :contained_aliquots, source: :request

  has_many :creation_batches, class_name: 'Batch', through: :requests_as_target, source: :batch

  belongs_to :purpose, foreign_key: :plate_purpose_id, optional: true, inverse_of: :labware

  has_one :spiked_in_buffer_links, # rubocop:todo Rails/HasManyOrHasOneDependent
          -> { includes(:ancestor).references(:ancestor).where(labware: { sti_type: 'SpikedBuffer' }).direct },
          class_name: 'AssetLink',
          foreign_key: :descendant_id,
          inverse_of: :descendant

  has_one :spiked_in_buffer_most_recent_links, # rubocop:todo Rails/HasManyOrHasOneDependent
          -> do
            includes(:ancestor)
              .references(:ancestor)
              .where(labware: { sti_type: 'SpikedBuffer' })
              .order(ancestor_id: :desc)
          end,
          class_name: 'AssetLink',
          foreign_key: :descendant_id,
          inverse_of: :descendant

  # Gets the SpikedBuffer tube that is a direct parent of this labware, if it exists.
  # The original implementation of spiked_in_buffer only supported direct parent tubes.
  has_one :direct_spiked_in_buffer, through: :spiked_in_buffer_links, source: :ancestor

  # Gets the most recent SpikedBuffer tube ancestor, if it exists, to use if there is no direct parent SpikedBuffer
  # tube.
  # Added to support PhiX being added during library prep rather than at sequencing time (for Heron).
  has_one :most_recent_spiked_in_buffer, through: :spiked_in_buffer_most_recent_links, source: :ancestor

  has_many :asset_audits, foreign_key: :asset_id, dependent: :destroy, inverse_of: :asset
  has_many :volume_updates, foreign_key: :target_id, dependent: :destroy, inverse_of: :target
  has_many :state_changes, foreign_key: :target_id, dependent: :destroy, inverse_of: :target
  has_one :custom_metadatum_collection, foreign_key: :asset_id, dependent: :destroy, inverse_of: :asset
  belongs_to :labware_type, class_name: 'PlateType', optional: true

  has_many :batches_as_source, -> { distinct }, through: :requests_as_source, source: :batch

  scope :with_required_aliquots, ->(aliquots_ids) { joins(:aliquots).where(aliquots: { id: aliquots_ids }) }

  has_many :qc_results, through: :receptacles

  scope :for_search_query,
        lambda { |query|
          where('labware.name LIKE :name', name: "%#{query}%").or(with_safe_id(query)).includes(:barcodes)
        }
  scope :for_lab_searches_display,
        lambda { includes(:barcodes, requests_as_source: %i[pipeline batch]).order('requests.pipeline_id ASC') }
  scope :named, ->(name) { where(name:) }
  scope :with_purpose, ->(*purposes) { where(plate_purpose_id: purposes.flatten) }
  scope :include_scanned_into_lab_event, -> { includes(:scanned_into_lab_event) }
  scope :include_creation_batches, -> { includes(:creation_batches) }

  # We accept not only an individual barcode but also an array of them.
  scope :with_barcode,
        lambda { |*barcodes|
          db_barcodes = Barcode.extract_barcodes(barcodes)
          joins(:barcodes).where(barcodes: { barcode: db_barcodes }).distinct
        }

  # In contrast to with_barocde, filter_by_barcode only filters in the event
  # a parameter is supplied. eg. an empty string does not filter the data
  scope :filter_by_barcode,
        lambda { |*barcodes|
          db_barcodes = Barcode.extract_barcodes(barcodes)
          if db_barcodes.blank?
            includes(:barcodes)
          else
            includes(:barcodes).where(barcodes: { barcode: db_barcodes }).distinct
          end
        }

  scope :source_assets_from_machine_barcode,
        lambda { |destination_barcode|
          destination_asset = find_by_barcode(destination_barcode)
          if destination_asset
            source_asset_ids = destination_asset.parents.map(&:id)
            source_asset_ids.empty? ? none : where(id: source_asset_ids)
          else
            none
          end
        }

  # The use of a sub-query here is a performance optimization. If we join onto the asset_links
  # table instead, rails is unable to paginate the results efficiently, as it needs to use DISTINCT
  # when working out offsets. This is substantially slower.
  # The check that ancestor_id is nil is necessary - a single null value means the query returns empty results.
  scope :without_children,
        -> { where.not(id: AssetLink.where(direct: true).where.not(ancestor_id: nil).select(:ancestor_id)) }
  scope :include_labware_with_children, ->(filter) { filter ? all : without_children }
  scope :stock_plates, -> { where(plate_purpose_id: PlatePurpose.considered_stock_plate) }

  delegate :state_changer, to: :purpose, allow_nil: true

  # Provided for API compatibility
  def state
    nil
  end

  def external_identifier
    "#{sti_type}#{id}"
  end

  def ancestor_of_purpose(ancestor_purpose_id)
    return self if plate_purpose_id == ancestor_purpose_id

    ancestors.order(id: :desc).find_by(plate_purpose_id: ancestor_purpose_id)
  end

  def ancestors_of_purpose(ancestor_purpose_id)
    return [self] if plate_purpose_id == ancestor_purpose_id

    ancestors.order(id: :desc).where(plate_purpose_id: ancestor_purpose_id)
  end

  # Gets the relevant SpikedBuffer tube, if one exists, by using the two associations.
  # A direct parent SpikedBuffer tube is used if it exists, otherwise the most recent ancestor.
  # This was necessary to avoid affecting historical data, for which the direct parent should be used,
  # even though there is another ancestor that was created more recently.
  def spiked_in_buffer
    direct_spiked_in_buffer || most_recent_spiked_in_buffer
  end

  def role
    (requests_as_source.first || in_progress_requests.first)&.role
  end

  def source_plate
    @source_plate ||= purpose&.source_plate(self)
  end

  def source_plates
    @source_plates ||= purpose&.source_plates(self)
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

  def received_date
    self
      &.asset_audits
      &.where(key: 'slf_receive_plates')
      &.where('message LIKE ?', '%Reception fridge%')
      &.last
      &.created_at
  end

  def retention_instructions
    @retention_instructions ||= obtain_retention_instructions
  end

  # Class methods
  class << self
    # Bulk retrieves locations for multiple labwares at once
    # Returns hash { labware barcode => location string, .. } e.g. { 'DN1234' => 'Sanger - Room 1 - Shelf 2' }
    # Hash has blank values where location was not found for a particular barcode
    # Or raises LabWhereClient::LabwhereException if Labwhere response is unexpected
    def labwhere_locations(labware_barcodes) # rubocop:todo Metrics/MethodLength
      info_from_labwhere = LabWhereClient::LabwareSearch.find_locations_by_barcodes(labware_barcodes)

      if info_from_labwhere.blank?
        raise LabWhereClient::LabwhereException, 'Labwhere service did not return information'
      end

      barcodes_to_parentage =
        info_from_labwhere.labwares.each_with_object({}) { |info, obj| obj[info.barcode] = info.location.location_info }

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
      elsif /\A[0-9]{1,7}\z/.match?(source_barcode)
        # Just a number
        joins(:barcodes).order(:id).find_by('barcodes.barcode LIKE "__?_"', source_barcode)
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

  def obtain_retention_instructions
    # first check the retention_instruction field
    return retention_instruction if retention_instruction.present?

    # if not found, check the metadata (legacy)
    return if metadata.blank?

    metadata.symbolize_keys[:retention_instruction]
  end

  def lookup_labwhere_location
    lookup_labwhere(machine_barcode) || lookup_labwhere(human_barcode)
  end

  def lookup_labwhere(barcode)
    begin
      info_from_labwhere = LabWhereClient::Labware.find_by_barcode(barcode)
    rescue StandardError => e
      # rescue LabWhereClient::LabwhereException => e
      Rails.logger.error { e }
      return 'Not found - There is a problem with Labwhere'
    end
    info_from_labwhere.location.location_info if info_from_labwhere.present? && info_from_labwhere.location.present?
  end
end
# rubocop:enable Metrics/ClassLength
