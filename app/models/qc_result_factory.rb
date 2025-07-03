# frozen_string_literal: true

# QcResultFactory
# creates a QcResult record from API request
class QcResultFactory
  include ActiveModel::Model

  validate :check_resources

  attr_accessor :lot_number

  def initialize(attributes = [])
    if attributes.is_a?(Array)
      build_resources(attributes)
    else
      @lot_number = attributes[:lot_number]
      build_resources(attributes[:qc_results])
    end
  end

  def resources
    @resources ||= []
  end

  def qc_assay
    @qc_assay ||= QcAssay.new(lot_number:)
  end

  def build_resources(assets)
    assets.each { |asset| resources << Resource.new(asset.merge(qc_assay:)) }
  end

  def except_blank_wells
    resources.reject(&:blank_well?)
  end

  def save
    return false unless valid?

    ActiveRecord::Base.transaction { except_blank_wells.collect(&:save) }
    true
  end

  def qc_results
    resources.collect(&:qc_result)
  end

  # QcResultFactory::Resource
  class Resource
    include ActiveModel::Model

    attr_accessor :well_location, :key, :value, :units, :cv, :assay_type, :assay_version, :qc_assay

    attr_reader :asset, :qc_result, :plate, :asset_identifier, :uuid, :barcode

    validate :check_asset_identifier, :check_asset, :check_qc_result

    def initialize(attributes = {})
      super(attributes)

      @asset = build_asset
      @qc_result = QcResult.new(asset:, key:, value:, units:, cv:, assay_type:, assay_version:, qc_assay:)
    end

    def message_id
      "Asset identifier - #{asset_identifier || 'blank'}"
    end

    def parent_plate
      @parent_plate ||= plate.parent
    end

    def uuid=(uuid)
      return if uuid.nil?

      @asset_identifier = uuid
      uuid_object = Uuid.find_by(external_id: uuid)
      return if uuid_object.blank?

      @uuid = uuid_object.resource_type == 'Sample' ? uuid_object.resource.primary_receptacle : uuid_object.resource
    end

    def barcode=(barcode)
      return if barcode.nil?

      @asset_identifier = barcode
      @barcode = Labware.find_by_barcode(barcode)
    end

    # This is where the complexity is.
    # First we need to find the uuid object.
    # Then we need to return the asset it relates to.
    # If the object is a sample we need to return it's primary receptacle which will be a well.
    # If the object is a tube then do nothing just return the asset.
    # If a well location is passed then assume it is a plate so we need to return the associated well.
    def build_asset
      asset = uuid || barcode
      return if asset.blank?
      return asset if well_location.blank?

      @plate = Plate.find(asset.id)
      plate.find_well_by_map_description(well_location)
    end

    def save
      return false unless valid?

      update_parent_well
      qc_result.save
    end

    def working_dilution?
      plate.instance_of? WorkingDilutionPlate
    end

    def concentration?
      key == 'concentration'
    end

    def can_update_parent_well?
      working_dilution? && concentration? && well_location.present? && plate.dilution_factor.present?
    end

    def update_parent_well
      return unless can_update_parent_well?

      well = parent_plate.find_well_by_map_description(well_location)
      parent_qc_result =
        QcResult.new(qc_result.attributes.merge(asset: well, value: value.to_f * plate.dilution_factor))
      parent_qc_result.save!
    end

    def blank_well?
      asset.blank? && well_location.present?
    end

    private

    def check_asset
      return if asset.present?
      return if well_location.present? && asset.blank?

      errors.add(:uuid, "#{message_id} does not belong to a valid asset")
    end

    def check_qc_result
      return if qc_result.valid?

      qc_result.errors.each do |error|
        errors.add error.attribute, error.message unless error.attribute == :asset && blank_well?
      end
    end

    def check_asset_identifier
      return if uuid.present? || barcode.present?

      errors.add(:base, 'must have an asset identifier - either a uuid or barcode')
    end
  end

  private

  def check_resources
    resources.each do |resource|
      next if resource.valid?

      resource_errors = resource.errors.map { |error| "#{error.attribute} #{error.message}" }.join(' ')
      errors.add(resource.message_id, resource_errors)
    end
  end
end
