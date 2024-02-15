# frozen_string_literal: true
# Generates wells for plate sample manifests
SampleManifest::GenerateWellsJob =
  Struct.new(:sample_manifest_id, :map_ids_to_sample_ids, :plate_id) do
    def perform
      ActiveRecord::Base.transaction do
        # Ensure the order of the wells are maintained
        # Why does the order of the wells matter? Maybe can't use a hash if it does.
        # Keep key of hash as map_id and query Maps in the generate_wells_job method?
        maps = Map.find(map_ids).index_by(&:id)
        well_data = {}
        map_ids_to_sample_ids.each do |map_id, sample_id|
          if (well_data[maps[map_id]])
            well_data[maps[map_id]] << sample_id
          else
            well_data[maps[map_id]] = [sample_id]
          end
        end

        sample_manifest.core_behaviour.generate_wells_job(well_data, plate)
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
