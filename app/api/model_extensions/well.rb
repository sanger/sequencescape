# Included in {Well}
# The intent of this file was to provide methods specific to the V1 API
module ModelExtensions::Well
  def self.included(base)
    base.class_eval do
      scope :for_api_plate_json, -> {
        preload(
          :map,
          :transfer_requests_as_target, # Should be :transfer_requests_as_target
          # :uuid_object is included elsewhere, and trying to also include it here
          # actually disrupts the eager loading.
          plate: :uuid_object,
          aliquots: Io::Aliquot::PRELOADS
        )
      }
    end
  end

  # Compatibility for v1 API maintains legacy 'type' for assets
  def legacy_asset_type
    labware.sti_type
  end
end
