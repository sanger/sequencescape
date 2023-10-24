# frozen_string_literal: true
module SampleManifest::SharedTubeBehaviour
  class Base
    include SampleManifest::CoreBehaviour::Shared

    def updated_by!(user, samples)
      # Does nothing at the moment
    end

    def details_array
      sample_manifest_assets
        .includes(asset: :barcodes)
        .map do |sample_manifest_asset|
          { barcode: sample_manifest_asset.human_barcode, sample_id: sample_manifest_asset.sanger_sample_id }
        end
    end

    private

    # rubocop:todo Metrics/MethodLength
    def generate_tubes(tube_purpose, number_of_tubes = count) # rubocop:todo Metrics/AbcSize
      sanger_ids = generate_sanger_ids(number_of_tubes)
      study_abbreviation = study.abbreviation

      tubes =
        Array.new(number_of_tubes) do
          tube = tube_purpose.create!
          sanger_sample_id = SangerSampleId.generate_sanger_sample_id!(study_abbreviation, sanger_ids.shift)
          SampleManifestAsset.create!(
            sanger_sample_id: sanger_sample_id,
            asset: tube.receptacle,
            sample_manifest: @manifest
          )
          tube
        end

      @manifest.update!(barcodes: tubes.map(&:human_barcode))

      delayed_generate_asset_requests(tubes.map { |tube| tube.receptacle.id }, study.id)
      tubes
    end

    # rubocop:enable Metrics/MethodLength

    def delayed_generate_asset_requests(asset_ids, study_id)
      Delayed::Job.enqueue GenerateCreateAssetRequestsJob.new(asset_ids, study_id)
    end
  end
end
