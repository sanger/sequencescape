# frozen_string_literal: true

# Generates the tubes for a compound sample manifest, e.g. Kinnex.
# Each physical tube holds one compound sample made from several component
# samples, so each tube gets several manifest rows, all showing the tube's
# barcode: one row for each tag in the component tag group.
module SampleManifest::CompoundTubeBehaviour
  class Core < SampleManifest::SampleTubeBehaviour::Core
    def generate
      @tubes = Array.new(count) { purpose.create! }
      add_rows_to_tubes
      @manifest.update!(barcodes: @tubes.map(&:human_barcode))
      generate_asset_requests
      @tubes
    end

    # The labware comes from the manifest assets, not from the samples:
    # only the compound sample is in the tube, not the component samples.
    def labware
      tubes | @manifest.assets.map(&:labware)
    end
    alias printables labware

    private

    # The components of a compound sample must all have different tags, so a
    # tube can have at most as many components as the tag group has tags.
    def rows_per_tube
      @rows_per_tube ||= component_tag_group.tags.count
    end

    def component_tag_group
      handler = SequencescapeExcel::SpecialisedField::ComponentTagSequence
      handler.tag_group ||
        raise(ActiveRecord::RecordNotFound,
              "Tag group #{handler::TAG_GROUP_NAME} not found")
    end

    def add_rows_to_tubes
      sanger_ids = generate_sanger_ids(count * rows_per_tube)
      @tubes.each do |tube|
        add_manifest_assets(tube, sanger_ids.shift(rows_per_tube))
      end
    end

    def generate_asset_requests
      receptacle_ids = @tubes.map { |tube| tube.receptacle.id }
      delayed_generate_asset_requests(receptacle_ids, study.id)
    end

    def add_manifest_assets(tube, sanger_ids)
      sanger_ids.each do |sanger_id|
        SampleManifestAsset.create!(
          sanger_sample_id: sanger_sample_id_for(sanger_id),
          asset: tube.receptacle,
          sample_manifest: @manifest
        )
      end
    end

    def sanger_sample_id_for(sanger_id)
      @study_abbreviation ||= study.abbreviation
      SangerSampleId.generate_sanger_sample_id!(@study_abbreviation, sanger_id)
    end
  end
end
