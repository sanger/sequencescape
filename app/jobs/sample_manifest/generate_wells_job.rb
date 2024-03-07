# frozen_string_literal: true
# Generates wells for plate sample manifests
SampleManifest::GenerateWellsJob =
  Struct.new(:sample_manifest_id, :map_ids_to_sanger_sample_ids, :plate_id) do
    # Passes the data back to the core behaviour class to generate the wells for the plate.
    def perform
      ActiveRecord::Base.transaction do
        maps = Map.find(map_ids).index_by(&:id)

        map_ids_to_sanger_sample_ids.each do |map_id, sanger_sample_ids|
          plate
            .wells
            .create!(map: maps[map_id]) do |well|
              sanger_sample_ids.each do |sanger_sample_id|
                SampleManifestAsset.create(
                  sanger_sample_id: sanger_sample_id,
                  asset: well,
                  sample_manifest: sample_manifest
                )
              end
            end
        end

        RequestFactory.create_assets_requests(plate.wells, sample_manifest.study)

        plate.events.created_using_sample_manifest!(sample_manifest.user)
      end
    end

    def map_ids
      map_ids_to_sanger_sample_ids.keys
    end

    def plate
      Plate.find(plate_id)
    end

    def sample_manifest
      SampleManifest.find(sample_manifest_id)
    end
  end
