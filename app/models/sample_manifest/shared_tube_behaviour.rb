module SampleManifest::SharedTubeBehaviour
  class Base
    include SampleManifest::CoreBehaviour::Shared

    def updated_by!(user, samples)
      # Does nothing at the moment
    end

    def details_array
      sample_manifest_assets.includes(asset: :barcodes).map do |sample_manifest_asset|
        {
          barcode: sample_manifest_asset.human_barcode,
          sample_id: sample_manifest_asset.sanger_sample_id
        }
      end
    end

    private

    def generate_tubes(purpose)
      sanger_ids = generate_sanger_ids(count)
      study_abbreviation = study.abbreviation

      tubes = Array.new(count) do
        tube = purpose.create!
        sanger_sample_id = SangerSampleId.generate_sanger_sample_id!(study_abbreviation, sanger_ids.shift)
        SampleManifestAsset.create!(sanger_sample_id: sanger_sample_id,
                                    asset: tube.receptacle,
                                    sample_manifest: @manifest)
        tube
      end

      @manifest.update!(barcodes: tubes.map(&:human_barcode))

      delayed_generate_asset_requests(tubes.map { |tube| tube.receptacle.id }, study.id)
      tubes
    end

    def delayed_generate_asset_requests(asset_ids, study_id)
      Delayed::Job.enqueue GenerateCreateAssetRequestsJob.new(asset_ids, study_id)
    end

    def generate_tube_racks(tube_purpose, tube_rack_purpose)
      sanger_ids = generate_sanger_ids(count*tube_rack_purpose.size)
      study_abbreviation = study.abbreviation

      tubes = Array.new(count*tube_rack_purpose.size) do
        tube = tube_purpose.create!
        sanger_sample_id = SangerSampleId.generate_sanger_sample_id!(study_abbreviation, sanger_ids.shift)
        SampleManifestAsset.create!(sanger_sample_id: sanger_sample_id,
                                    asset: tube.receptacle,
                                    sample_manifest: @manifest)
        tube
      end

      @manifest.update!(barcodes: tubes.map(&:human_barcode))

      delayed_generate_asset_requests(tubes.map { |tube| tube.receptacle.id }, study.id)
      tubes
    end

  end


end
