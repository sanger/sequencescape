# frozen_string_literal: true
# Generates wells and sample manifest assets, for a plate sample manifest.
SampleManifest::GenerateWellsJob =
  Struct.new(:sample_manifest_id, :map_ids_to_sanger_sample_ids, :plate_id) do
    def perform
      ActiveRecord::Base.transaction do
        map_ids_to_sanger_sample_ids.each { |map_id, sanger_sample_id| create_well(map_id, sanger_sample_id) }

        RequestFactory.create_assets_requests(plate.wells, sample_manifest.study)

        plate.events.created_using_sample_manifest!(sample_manifest.user)
      end
    end

    def create_well(map_id, sanger_sample_ids)
      plate.wells.create!(map: Map.find(map_id)) { |well| create_sample_manifest_assets(well, sanger_sample_ids) }
    end

    def plate
      Plate.find(plate_id)
    end

    def create_sample_manifest_assets(well, sanger_sample_ids)
      sanger_sample_ids.each do |sanger_sample_id|
        SampleManifestAsset.create(sanger_sample_id: sanger_sample_id, asset: well, sample_manifest: sample_manifest)
      end
    end

    def sample_manifest
      SampleManifest.find(sample_manifest_id)
    end
  end
