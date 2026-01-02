# frozen_string_literal: true
module SampleManifest::PlateBehaviour
  class Base
    include SampleManifest::CoreBehaviour::Shared
    include SampleManifest::CoreBehaviour::NoSpecializedValidation

    attr_reader :plates

    def initialize(manifest)
      @manifest = manifest
      @plates = []
    end

    # Generates plates and associated data for the sample manifest.
    #
    # Steps:
    # 1. Generates new plates for the given purpose.
    # 2. Inserts Sanger sample IDs for the plates.
    # 3. Builds well data mapping plates, maps, and sample IDs.
    # 4. Enqueues asynchronous jobs to build wells for each plate.
    # 5. Constructs an array of details for each well.
    # 6. Updates the manifest with the barcodes of the generated plates.
    def generate
      @plates = generate_plates(purpose)

      sanger_sample_ids = insert_sanger_sample_ids
      well_data = build_well_data(sanger_sample_ids)

      build_wells_async(well_data)

      @details_array = build_details_array(well_data)

      @manifest.update!(barcodes: @plates.map(&:human_barcode))
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
      plates | Labware.with_barcode(barcodes)
    end
    alias printables labware

    private

    def generate_plates(purpose)
      Array.new(count) { purpose.create!(:without_wells) }.sort_by(&:human_barcode)
    end

    def insert_sanger_sample_ids
      sanger_sample_ids = generate_sanger_ids(@plates.sum(&:size) * @manifest.rows_per_well)
      sanger_sample_ids.map do |sanger_sample_id|
        SangerSampleId.generate_sanger_sample_id!(study.abbreviation, sanger_sample_id)
      end
    end

    # output:
    # plate_id => { map_id => [sanger_sample_id, sanger_sample_id, ...] }
    def build_well_data(sanger_sample_ids)
      @plates.each_with_object({}) do |plate, well_data|
        well_data[plate.id] = {}

        plate.maps.in_column_major_order.each do |well_map|
          well_data[plate.id][well_map.id] = sanger_sample_ids.shift(@manifest.rows_per_well)
        end
      end
    end

    # Each of the plates is handled by an individual job.
    # If it doesn't do this we run the risk that the 'handler' column in the database
    # for the delayed job will not be large enough and will truncate the data.
    def build_wells_async(well_data)
      @plates.each do |plate|
        Delayed::Job.enqueue SampleManifest::GenerateWellsJob.new(@manifest.id, well_data[plate.id], plate.id)
      end
    end

    # output:
    # [{barcode, position, sanger_sample_id}, {barcode, position, sanger_sample_id}, ...]
    def build_details_array(well_data)
      @details_array =
        @plates.flat_map do |plate|
          well_data[plate.id].flat_map do |map_id, sanger_sample_ids|
            sanger_sample_ids.map do |sanger_sample_id|
              {
                barcode: plate.human_barcode,
                position: plate.maps.find(map_id).description,
                sample_id: sanger_sample_id
              }
            end
          end
        end
    end
  end

  class Core < Base
    include SampleManifest::CoreBehaviour::StockAssets
  end
end
