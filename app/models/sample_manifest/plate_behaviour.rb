module SampleManifest::PlateBehaviour
  module ClassMethods
    def create_for_plate!(attributes, *args, &block)
      create!(attributes.merge(:asset_type => 'plate'), *args, &block).tap do |manifest|
        manifest.generate
      end
    end
  end

  class Core
    def initialize(manifest)
      @manifest = manifest
    end

    delegate :generate_plates, :to => :@manifest
    alias_method(:generate, :generate_plates)

    delegate :samples, :to => :@manifest

    def io_samples
      samples.map do |sample|
        container = sample.primary_well
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
      plates              = self.samples.map { |s| s.primary_well.plate }.uniq.sort_by(&:barcode)
      stock_plate_purpose = PlatePurpose.stock_plate_purpose
      printables          = stock_plate_purpose.create_barcode_labels_from_plates(plates)
      yield(printables, Plate.prefix, "long", stock_plate_purpose.name.to_s)
    end

    def updated_by!(user, samples)
      samples.map { |s| s.wells.map(&:plate) }.flatten.uniq.each do |plate|
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
  
  def generate_plates
    study_abbreviation = self.study.abbreviation

    well_data = []
    plates    = (0...self.count).map do |_|
      Plate.create_plate_with_barcode(:plate_purpose => stock_plate_purpose)
    end.sort_by(&:barcode).map do |plate|
      plate.tap do |plate|
        sanger_sample_ids = generate_sanger_ids(plate.size)

        Map.walk_plate_vertically(plate.size) do |map|
          sanger_sample_id           = sanger_sample_ids.shift
          generated_sanger_sample_id = SangerSampleId.generate_sanger_sample_id!(study_abbreviation, sanger_sample_id)

          well_data << [map, generated_sanger_sample_id]
        end
      end
    end

    generate_wells(well_data, plates)
    self.barcodes = plates.map(&:sanger_human_barcode)

    delayed_generate_asset_requests(plates, self.study)
    save!
  end

  def generate_wells(well_data, plates)
    plates.each_with_index do |plate, index|
      wells_for_plate = well_data.slice!(0, plate.size)
      study_samples_data = wells_for_plate.map do |map,sanger_sample_id|
        create_sample(sanger_sample_id).tap do |sample|
          plate.wells.create!(:map => map, :sample => sample, :well_attribute => WellAttribute.new)
        end
      end

      delayed_generate_study_samples(study_samples_data.map { |sample| [ study.id, sample.id ] })
      plate.events.created_using_sample_manifest!(self.user)

      RequestFactory.create_assets_requests(plate.wells.map(&:id), study.id)
    end
  end
  private :generate_wells
end
