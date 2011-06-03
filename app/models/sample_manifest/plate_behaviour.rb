module SampleManifest::PlateBehaviour
  module ClassMethods
    def create_for_plate!(attributes, *args, &block)
      create!(attributes.merge(:asset_type => 'plate'), *args, &block).tap do |manifest|
        manifest.generate
      end
    end
  end

  class Base
    def initialize(manifest)
      @manifest = manifest
    end

    delegate :generate_plates, :to => :@manifest
    alias_method(:generate, :generate_plates)

    delegate :samples, :to => :@manifest

    def print_labels_for(plates, &block)
      plates              = plates.sort_by(&:barcode)
      stock_plate_purpose = PlatePurpose.stock_plate_purpose
      printables          = stock_plate_purpose.create_barcode_labels_from_plates(plates)
      yield(printables, Plate.prefix, "long", stock_plate_purpose.name.to_s)
    end

    # This method ensures that each of the plates is handled by an individual job.  If it doesn't do this we run
    # the risk that the 'handler' column in the database for the delayed job will not be large enough and will
    # truncate the data.
    def generate_wells_for_plates(well_data, plates, &block)
      cloned_well_data = well_data.dup
      plates.each do |plate|
        block.call(
          cloned_well_data.slice!(0, plate.size),
          plate
        )
      end
    end
    private :generate_wells_for_plates
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
          this_plates_well_data.map { |map,sample_id| [map.id, sample_id] },
          plate.id
        )
      end

      # Ensure we maintain the information we need for printing labels and generating
      # the CSV file
      @plates  = plates.sort_by(&:barcode)
      @details = []
      plates.each do |plate|
        well_data.slice!(0, plate.size).each do |map,sample_id|
          @details << {
            :barcode   => plate.sanger_human_barcode,
            :position  => map.description,
            :sample_id => sample_id
          }
        end
      end
    end

    def print_labels(&block)
      print_labels_for(@plates, &block)
    end

    def details(&block)
      @details.map(&block.method(:call))
    end
  end

  class Core < Base
    def generate_wells(well_data, plates)
      generate_wells_for_plates(well_data, plates, &@manifest.method(:generate_wells))
    end

    def io_samples
      samples.map do |sample|
        container = sample.primary_receptacle
        {
          :sample    => sample,
          :container => {
            :barcode  => container.plate.sanger_human_barcode,
            :position => container.map.description.sub(/^([^\d]+)(\d)$/, '\10\2')
          }
        }
      end
    end

    def print_labels(&block)
      print_labels_for(self.samples.map { |s| s.primary_receptacle.plate }.uniq, &block)
    end

    def updated_by!(user, samples)
      samples.map { |s| s.wells.map(&:plate) }.flatten.uniq.select{ |well_container| ! well_container.nil? }.each do |plate|
        plate.events.updated_using_sample_manifest!(user)
      end
    end

    def details(&block)
      samples.each do |sample|
        well = sample.wells.first(:include => [ :container, :map ])
        yield({
          :barcode   => well.plate.sanger_human_barcode,
          :position  => well.map.description,
          :sample_id => sample.sanger_sample_id
        })
      end
    end
  end

  def self.included(base)
    base.class_eval do
      extend ClassMethods

      delegate :stock_plate_purpose, :to => 'PlatePurpose'
    end
  end

  def generate_wells_asynchronously(well_data_with_ids, plate_id)
    # Ensure the order of the wells are maintained
    maps      = Hash[Map.find(well_data_with_ids.map(&:first)).map { |map| [ map.id, map ] }]
    well_data = well_data_with_ids.map { |map_id,sample_id| [ maps[map_id], sample_id ] }

    generate_wells(well_data, Plate.find(plate_id))
  end
  handle_asynchronously :generate_wells_asynchronously

  def generate_plates
    study_abbreviation = self.study.abbreviation

    well_data = []
    plates    = (0...self.count).map do |_|
      Plate.create_with_barcode!(:plate_purpose => stock_plate_purpose)
    end.sort_by(&:barcode).map do |plate|
      plate.tap do |plate|
        sanger_sample_ids = generate_sanger_ids(plate.size)

        Map.walk_plate_in_column_major_order(plate.size) do |map, _|
          sanger_sample_id           = sanger_sample_ids.shift
          generated_sanger_sample_id = SangerSampleId.generate_sanger_sample_id!(study_abbreviation, sanger_sample_id)

          well_data << [map, generated_sanger_sample_id]
        end
      end
    end

    core_behaviour.generate_wells(well_data, plates)
    self.barcodes = plates.map(&:sanger_human_barcode)
    RequestFactory.create_assets_requests(plates.map(&:id), self.study.id)

    save!
  end

  def generate_wells(wells_for_plate, plate)
    study_samples_data = wells_for_plate.map do |map,sanger_sample_id|
      create_sample(sanger_sample_id).tap do |sample|
        plate.wells.create!(:map => map, :well_attributes => WellAttribute.new).tap do |well|
          well.aliquots.create!(:sample => sample)
        end
      end
    end

    generate_study_samples(study_samples_data.map { |sample| [ study.id, sample.id ] })
    plate.events.created_using_sample_manifest!(self.user)

    RequestFactory.create_assets_requests(plate.wells.map(&:id), study.id)
  end
  private :generate_wells
end
