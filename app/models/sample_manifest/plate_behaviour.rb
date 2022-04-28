# frozen_string_literal: true
module SampleManifest::PlateBehaviour
  class Base # rubocop:todo Style/Documentation
    include SampleManifest::CoreBehaviour::Shared
    include SampleManifest::CoreBehaviour::NoSpecializedValidation

    attr_reader :plates

    def initialize(manifest)
      @manifest = manifest
      @plates = []
    end

    def generate
      @plates = generate_plates(purpose)
    end

    def acceptable_purposes
      PlatePurpose.for_submissions
    end

    def default_purpose
      PlatePurpose.stock_plate_purpose
    end

    def included_resources
      [{ sample: :sample_metadata, asset: { plate: :barcodes } }]
    end

    def generate_wells(well_data, plates)
      # Generate the wells, samples & requests asynchronously.
      generate_wells_for_plates(well_data, plates) do |this_plates_well_data, plate|
        generate_wells_asynchronously(this_plates_well_data.map { |map, sample_id| [map.id, sample_id] }, plate.id)
      end

      # Ensure we maintain the information we need for printing labels and generating
      # the CSV file
      @plates = plates.sort_by(&:human_barcode)

      @details_array =
        plates.flat_map do |plate|
          well_data
            .slice!(0, plate.size)
            .map { |map, sample_id| { barcode: plate.human_barcode, position: map.description, sample_id: sample_id } }
        end
    end

    def io_samples
      samples.map do |sample|
        container = sample.primary_receptacle
        {
          sample: sample,
          container: {
            barcode: container.plate.human_barcode,
            position: container.map.description.sub(/^([^\d]+)(\d)$/, '\10\2')
          }
        }
      end
    end

    def updated_by!(user, samples)
      # It's more efficient to look for the wells with the samples than to look for the assets from the samples
      # themselves as the former can use named_scopes where as the latter is an array that needs iterating over.
      Plate.with_sample(samples).each { |plate| plate.events.updated_using_sample_manifest!(user) }
    end

    def details_array
      @details_array ||=
        sample_manifest_assets
          .includes(asset: [:map, :aliquots, { plate: :barcodes }])
          .map do |sample_manifest_asset|
            {
              barcode: sample_manifest_asset.asset.plate.human_barcode,
              position: sample_manifest_asset.asset.map_description,
              sample_id: sample_manifest_asset.sanger_sample_id
            }
          end
    end

    def labware=(labware)
      @plates = labware
    end

    # We use the barcodes here as we may need to reference the plates before the delayed job has passed
    def labware
      plates | labware_from_barcodes
    end
    alias printables labware

    # Called by {SampleManifest::GenerateWellsJob} and builds the wells
    def generate_wells_job(wells_for_plate, plate)
      wells_for_plate.map do |map, sanger_sample_id|
        plate
          .wells
          .create!(map: map) do |well|
            SampleManifestAsset.create(sanger_sample_id: sanger_sample_id, asset: well, sample_manifest: @manifest)
          end
      end
      RequestFactory.create_assets_requests(plate.wells, study)
      plate.events.created_using_sample_manifest!(@manifest.user)
    end

    private

    # This method ensures that each of the plates is handled by an individual job.  If it doesn't do this we run
    # the risk that the 'handler' column in the database for the delayed job will not be large enough and will
    # truncate the data.
    def generate_wells_for_plates(well_data, plates)
      cloned_well_data = well_data.dup
      plates.each { |plate| yield(cloned_well_data.slice!(0, plate.size), plate) }
    end

    def labware_from_barcodes
      Labware.with_barcode(barcodes)
    end

    def generate_wells_asynchronously(map_ids_to_sample_ids, plate_id)
      Delayed::Job.enqueue SampleManifest::GenerateWellsJob.new(@manifest.id, map_ids_to_sample_ids, plate_id)
    end

    # rubocop:todo Metrics/MethodLength
    def generate_plates(purpose) # rubocop:todo Metrics/AbcSize
      study_abbreviation = study.abbreviation

      well_data = []
      plates = Array.new(count) { purpose.create!(:without_wells) }.sort_by(&:human_barcode)

      plates.each do |plate|
        sanger_sample_ids = generate_sanger_ids(plate.size)

        plate.maps.in_column_major_order.each do |well_map|
          sanger_sample_id = sanger_sample_ids.shift
          generated_sanger_sample_id = SangerSampleId.generate_sanger_sample_id!(study_abbreviation, sanger_sample_id)

          well_data << [well_map, generated_sanger_sample_id]
        end
      end

      generate_wells(well_data, plates)
      @manifest.update!(barcodes: plates.map(&:human_barcode))

      plates
    end
    # rubocop:enable Metrics/MethodLength
  end

  class Core < Base
    include SampleManifest::CoreBehaviour::StockAssets
  end
end
