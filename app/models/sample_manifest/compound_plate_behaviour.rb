# frozen_string_literal: true

# Generates the plates for a compound sample manifest, e.g. Kinnex.
# Each physical plate well holds one compound sample made from several component
# samples, so each plate gets several manifest rows, all showing the plate's
# barcode: one row for each tag in the component tag group.
module SampleManifest::CompoundPlateBehaviour
  class Core < SampleManifest::PlateBehaviour::Core
    def generate
      @plates = Array.new(count) { purpose.create!(:without_wells) }
      add_rows_to_plates
      @manifest.update!(barcodes: @plates.map(&:human_barcode))
      @plates
    end

    # The labware comes from the manifest assets, not from the samples:
    # only the compound sample is in the plate, not the component samples.
    def labware
      plates | @manifest.assets.map(&:labware)
    end
    alias printables labware

    # The component samples are not in the plate: only the compound sample is.
    def samples_in_receptacles?
      false
    end

    # A plate has a row for each component, but it is one stock resource that
    # holds only its compound sample, so it is registered once.
    def stock_receptacles(receptacles)
      receptacles.uniq
    end

    # Creates a component sample on upload, without an aliquot in the plate.
    # The name and arguments are shared by all manifest behaviours.
    def generate_sample_and_aliquot(sanger_sample_id, _receptacle)
      create_sample(sanger_sample_id).tap { |sample| study.samples << sample }
    end

    private

    # The components of a compound sample must all have different tags, so a
    # plate can have at most as many components as the tag group has tags.
    def rows_per_plate
      @rows_per_plate ||= component_tag_group.tags.count
    end

    def component_tag_group
      handler = SequencescapeExcel::SpecialisedField::ComponentTagSequence
      handler.tag_group ||
        raise(ActiveRecord::RecordNotFound,
              "Tag group #{handler::TAG_GROUP_NAME} not found")
    end

    def add_rows_to_plates
      sanger_ids = generate_sanger_ids(count * rows_per_plate)
      @plates.each do |plate|
        add_manifest_assets(plate, sanger_ids.shift(rows_per_plate))
      end
    end

    def add_manifest_assets(plate, sanger_ids)
      sanger_ids.each do |sanger_id|
        SampleManifestAsset.create!(
          sanger_sample_id: sanger_sample_id_for(sanger_id),
          asset: plate.wells.first.receptacle,
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
