# Generates wells for plate sample manifests
SampleManifest::GenerateWellsJob = Struct.new(:sample_manifest_id, :map_ids_to_sample_ids, :plate_id) do
  def perform
    ActiveRecord::Base.transaction do
      # Ensure the order of the wells are maintained
      maps      = Map.find(map_ids).index_by(&:id)
      well_data = map_ids_to_sample_ids.map { |map_id, sample_id| [maps[map_id], sample_id] }

      sample_manifest.generate_wells(well_data, plate)
    end
  end

  def map_ids
    map_ids_to_sample_ids.map(&:first)
  end

  def plate
    Plate.find(plate_id)
  end

  def sample_manifest
    SampleManifest.find(sample_manifest_id)
  end
end
