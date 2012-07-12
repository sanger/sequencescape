module SampleManifest::SampleTubeBehaviour
  module ClassMethods
    def create_for_sample_tube!(attributes, *args, &block)
      create!(attributes.merge(:asset_type => '1dtube'), *args, &block).tap do |manifest|
        manifest.generate
      end
    end
  end

  class Core
    def initialize(manifest)
      @manifest = manifest
    end

    delegate :generate_1dtubes, :to => :@manifest
    alias_method(:generate, :generate_1dtubes)

    delegate :samples, :to => :@manifest

    def io_samples
      samples.map do |sample|
        {
          :sample    => sample,
          :container => {
            :barcode => sample.primary_receptacle.sanger_human_barcode
          }
        }
      end
    end

    def print_labels(&block)
      printables = self.samples.map do |sample|
        sample_tube = sample.assets.first
        PrintBarcode::Label.new(
          :number => sample_tube.sanger_human_barcode,
          :study  => sample.sanger_sample_id,
          :prefix => sample_tube.prefix, :suffix => ""
        )
      end
      yield(printables, 'NT')
    end

    def updated_by!(user, samples)
      # Does nothing at the moment
    end

    def details(&block)
      samples.each do |sample|
        yield({
          :barcode   => sample.assets.first.sanger_human_barcode,
          :sample_id => sample.sanger_sample_id
        })
      end
    end

    def validate_sample_container(sample, row, &block)
      manifest_barcode, primary_barcode = row['SOMETHING'], sample.primary_receptacle.sanger_human_barcode
      return if primary_barcode == manifest_barcode
      yield("Tube info for #{sample.sanger_sample_id} mismatch: expected #{primary_barcode} but reported as #{manifest_barcode}")
    end
  end

  # There is no reason for this to need a rapid version as it should be reasonably
  # efficient in the first place.
  RapidCore = Core

  def self.included(base)
    base.class_eval do
      extend ClassMethods
    end
  end

  def generate_1dtubes
    sanger_ids = generate_sanger_ids(self.count)
    study_abbreviation = self.study.abbreviation

    tubes, samples_data = [], []
    (0...self.count).each do |_|
      sample_tube = Tube::Purpose.standard_sample_tube.create!
      sanger_sample_id = SangerSampleId.generate_sanger_sample_id!(study_abbreviation, sanger_ids.shift)

      tubes << sample_tube
      samples_data << [sample_tube.barcode,sanger_sample_id,sample_tube.prefix]
    end

    self.barcodes = tubes.map(&:sanger_human_barcode)

    sample_tube_sample_creation(samples_data,self.study.id)
    delayed_generate_asset_requests(tubes.map(&:id), self.study.id)
    save!
  end

  def delayed_generate_asset_requests(asset_ids,study_id)
    RequestFactory.create_assets_requests(asset_ids, study_id)
  end
  handle_asynchronously :delayed_generate_asset_requests

  def sample_tube_sample_creation(samples_data,study_id)
    study.samples << samples_data.map do |barcode, sanger_sample_id, prefix|
      create_sample(sanger_sample_id).tap do |sample|
        sample_tube = SampleTube.find_by_barcode(barcode) or raise ActiveRecord::RecordNotFound, "Cannot find sample tube with barcode #{barcode.inspect}"
        sample_tube.aliquots.create!(:sample => sample)
      end
    end
  end
  private :sample_tube_sample_creation
end
