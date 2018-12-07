module SampleManifest::PlateBehaviour
  module ClassMethods
    def create_for_plate!(attributes, *args, &block)
      create!(attributes.merge(asset_type: 'plate'), *args, &block).tap do |manifest|
        manifest.generate
      end
    end
  end

  class Base
    include SampleManifest::CoreBehaviour::NoSpecializedValidation

    attr_reader :plates

    def initialize(manifest)
      @manifest = manifest
      @plates = []
    end

    def acceptable_purposes
      PlatePurpose.for_submissions
    end

    delegate :generate_plates, to: :@manifest
    alias_method(:generate, :generate_plates)

    delegate :generate_sample_and_aliquot, to: :@manifest
    delegate :samples, to: :@manifest

    # This method ensures that each of the plates is handled by an individual job.  If it doesn't do this we run
    # the risk that the 'handler' column in the database for the delayed job will not be large enough and will
    # truncate the data.
    def generate_wells_for_plates(well_data, plates)
      cloned_well_data = well_data.dup
      plates.each do |plate|
        yield(cloned_well_data.slice!(0, plate.size), plate)
      end
    end
    private :generate_wells_for_plates

    def validate_sample_container(sample, row)
      manifest_barcode, manifest_location = row['SANGER PLATE ID'], row['WELL']
      primary_barcode, primary_location   = sample.primary_receptacle.plate.human_barcode, sample.primary_receptacle.map.description
      return if primary_barcode == manifest_barcode and primary_location == manifest_location

      yield("You can not move samples between wells or modify barcodes: #{sample.sanger_sample_id} should be in '#{primary_barcode} #{primary_location}' but the manifest is trying to put it in '#{manifest_barcode} #{manifest_location}'")
    end
  end

  #--
  # This class is only used by the UI version of Sequencescape and so it only supports a subset of
  # the methods required.  It can be used to generate the Excel file and to print the labels but it
  # could not be used for the API not for handling the uploaded sample manifest CSV file.
  #++
  class RapidCore < Base
    def generate_wells(well_data, plates)
      # Generate the wells, samples & requests asynchronously.
      generate_wells_for_plates(well_data, plates) do |this_plates_well_data, plate|
        @manifest.generate_wells_asynchronously(
          this_plates_well_data.map { |map, sample_id| [map.id, sample_id] },
          plate.id
        )
      end

      # Ensure we maintain the information we need for printing labels and generating
      # the CSV file
      @plates  = plates.sort_by(&:human_barcode)
      @details = []
      plates.each do |plate|
        well_data.slice!(0, plate.size).each do |map, sample_id|
          @details << {
            barcode: plate.human_barcode,
            position: map.description,
            sample_id: sample_id
          }
        end
      end
    end

    def details(&block)
      @details.map(&block.method(:call))
    end

    def details_array
      @details
    end

    def labware
      plates
    end
    alias printables labware
  end

  class Core < Base
    def generate_wells(well_data, plates)
      @plates = plates.sort_by(&:human_barcode)
      generate_wells_for_plates(well_data, plates, &@manifest.method(:generate_wells))
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
      Plate.with_sample(samples).each do |plate|
        plate.events.updated_using_sample_manifest!(user)
      end
    end

    def details
      samples.each do |sample|
        well = sample.wells.includes([:container, :map]).first
        yield({
          barcode: well.plate.human_barcode,
          position: well.map.description,
          sample_id: sample.sanger_sample_id
        })
      end
    end

    def labware_from_samples
      samples.map { |s| s.primary_receptacle.plate }.uniq
    end

    def labware=(labware)
      @plates = labware
    end

    def labware
      labware_from_samples | plates
    end
    alias printables labware
  end

  def self.included(base)
    base.class_eval do
      extend ClassMethods

      delegate :stock_plate_purpose, to: 'PlatePurpose'
    end
  end

  def generate_wells_asynchronously(map_ids_to_sample_ids, plate_id)
    Delayed::Job.enqueue SampleManifest::GenerateWellsJob.new(id, map_ids_to_sample_ids, plate_id)
  end

  # Fall back to stock plate by default
  def purpose
    super || stock_plate_purpose
  end

  def purpose_id
    super || purpose.id
  end

  def generate_plates
    study_abbreviation = study.abbreviation

    well_data = []
    plates = Array.new(count) { purpose.create!(:without_wells) }.sort_by(&:human_barcode)

    plates.each do |plate|
      sanger_sample_ids = generate_sanger_ids(plate.size)

      Map.walk_plate_in_column_major_order(plate.size) do |map, _|
        sanger_sample_id           = sanger_sample_ids.shift
        generated_sanger_sample_id = SangerSampleId.generate_sanger_sample_id!(study_abbreviation, sanger_sample_id)

        well_data << [map, generated_sanger_sample_id]
      end
    end

    core_behaviour.generate_wells(well_data, plates)
    self.barcodes = plates.map(&:human_barcode)

    save!
    @plates = plates.sort_by(&:human_barcode)
  end

  def generate_sample_and_aliquot(sanger_sample_id, well)
    create_sample(sanger_sample_id).tap do |sample|
      well.aliquots.build(sample: sample)
      well.register_stock!
      study.samples << sample
    end
  end

  def generate_wells(wells_for_plate, plate)
    wells_for_plate.map do |map, sanger_sample_id|
      plate.wells.create!(map: map) do |well|
        SampleManifestAsset.create(sanger_sample_id: sanger_sample_id,
                                   asset: well,
                                   sample_manifest: self)
      end
    end
    RequestFactory.create_assets_requests(plate.wells, study)
    plate.events.created_using_sample_manifest!(user)
  end
end
