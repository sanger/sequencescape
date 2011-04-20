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
        container = sample.assets.first
        ::ModelExtensions::SampleManifest::SampleMapper.new(
          sample,
          :barcode => container.plate.sanger_human_barcode,
          :well    => container.map.description.sub(/^([^\d]+)(\d)$/, '\10\2')
        )
      end
    end

    def print_labels(&block)
      plates              = self.samples.map { |s| s.wells.first.plate }.uniq
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

    plates = (0...self.count).map do |_|
      Plate.create_plate_with_barcode(:plate_purpose => stock_plate_purpose)
    end.sort_by(&:barcode).map do |plate|
      plate.tap do |plate|
        sanger_sample_ids = generate_sanger_ids(plate.size)
        position = "A1"
        well_data = []

        while position
          sanger_sample_id = sanger_sample_ids.shift
          generated_sanger_sample_id = SangerSampleId.generate_sanger_sample_id!(study_abbreviation, sanger_sample_id)

          well_data << [position, generated_sanger_sample_id]
          position = Map.next_vertical_map_position_from_description(position,plate.size).try(:description)
        end
        generate_wells(well_data, plate.id, self.study.id)
      end
    end

    self.barcodes = plates.map(&:sanger_human_barcode)

    delayed_generate_asset_requests(plates, self.study)
    save!
  end

  def generate_wells(well_data, plate_id, study_id)
    plate = Plate.find(plate_id)

    study_samples_data = well_data.map do |position,sanger_sample_id|
      sample = SampleManifest.create_sample("", self, sanger_sample_id)
      map    = Map.find_by_description_and_asset_size(position,plate.size)
      Well.create!(:plate => plate, :map => map, :sample => sample)

      [study_id, sample.id]
    end
    delayed_generate_study_samples(study_samples_data)
    plate.save
    plate.reload
    plate.create_well_attributes(plate.wells)
    plate.events.created_using_sample_manifest!(self.user)

    RequestFactory.create_assets_requests(plate.wells.map(&:id), study_id)

    nil
  end
  private :generate_wells
end
