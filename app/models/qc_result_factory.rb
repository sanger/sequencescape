# frozen_string_literal: true

# QcResultFactory
# creates a QcResult record from API request
class QcResultFactory
  include ActiveModel::Model

  validate :check_resources

  def initialize(attributes = [])
    build_resources(attributes)
  end

  def resources
    @resources ||= []
  end

  def build_resources(assets)
    assets.each do |asset|
      resources << Resource.new(asset)
    end
  end

  def save
    return false unless valid?
    resources.collect(&:save)
    true
  end

  def qc_results
    resources.collect(&:qc_result)
  end

  # QcResultFactory::Resource
  class Resource
    include ActiveModel::Model

    attr_accessor :uuid, :well_location, :key, :value, :units, :cv, :assay_type, :assay_version

    attr_reader :asset, :qc_result

    validates :uuid, presence: true

    validate :check_asset, :check_qc_result

    def initialize(attributes = {})
      super(attributes)

      @asset = build_asset
      @qc_result = QcResult.new(asset: asset, key: key, value: value, units: units, cv: cv, assay_type: assay_type, assay_version: assay_version)
    end

    def message_id
      "Uuid - #{(uuid || 'blank')}"
    end

    # This is where the complexity is.
    # First we need to find the uuid object.
    # Then we need to return the asset it relates to.
    # If the object is a sample we need to return it's primary receptacle which will be a well.
    # If the object is a tube then do nothing just return the asset.
    # If a well location is passed then assume it is a plate so we need to return the associated well.
    def build_asset
      uuid_object = Uuid.find_by(external_id: uuid)
      return if uuid_object.blank?
      asset = if uuid_object.resource_type == 'Sample'
                Sample.find(uuid_object.resource_id).primary_receptacle
              else
                Asset.find(uuid_object.resource_id)
              end
      return asset if well_location.blank?
      plate = Plate.find(asset.id)
      plate.find_well_by_map_description(well_location)
    end

    def save
      return false unless valid?
      qc_result.save
    end

    private

    def check_asset
      return if asset.present?
      errors.add(:uuid, 'does not belong to a valid asset')
    end

    def check_qc_result
      return if qc_result.valid?
      qc_result.errors.each do |k, v|
        errors.add(k, v)
      end
    end
  end

  private

  def check_resources
    resources.each do |resource|
      next if resource.valid?
      String.new.tap do |resource_errors|
        resource.errors.each do |key, value|
          resource_errors << "#{key} #{value} "
        end
        errors.add(resource.message_id, resource_errors)
      end
    end
  end
end
