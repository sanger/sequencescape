module SampleManifest::SampleTubeBehaviour
  module ClassMethods
    def create_for_sample_tube!(attributes, *args, &block)
      create!(attributes.merge(asset_type: '1dtube'), *args, &block).tap do |manifest|
        manifest.generate
      end
    end
  end

  class Core
    include SampleManifest::CoreBehaviour::NoSpecializedValidation

    attr_reader :tubes

    delegate :generate_1dtubes, to: :@manifest
    delegate :samples, :sample_manifest_assets, to: :@manifest

    def initialize(manifest)
      @manifest = manifest
      @tubes = []
    end

    def generate
      @tubes = generate_1dtubes
    end

    def generate_sample_and_aliquot(sanger_sample_id, tube)
      sample = @manifest.build_sample_and_aliquot(sanger_sample_id, tube)
      tube.register_stock!
      sample
    end

    def io_samples
      samples.map do |sample|
        {
          sample: sample,
          container: {
            barcode: sample.primary_receptacle.human_barcode
          }
        }
      end
    end

    def acceptable_purposes
      [Tube::Purpose.standard_sample_tube, Tube::Purpose.find_by(name: 'saphyr')]
    end

    def updated_by!(user, samples)
      # Does nothing at the moment
    end

    def details(&block)
      details_array.each(&block)
    end

    def details_array
      sample_manifest_assets.includes(asset: :barcodes).map do |sample_manifest_asset|
        {
          barcode: sample_manifest_asset.human_barcode,
          sample_id: sample_manifest_asset.sanger_sample_id
        }
      end
    end

    def labware_from_samples
      samples.map { |sample| sample.assets.first }
    end

    def labware=(labware)
      @tubes = labware
    end

    def labware
      tubes | labware_from_samples | @manifest.assets
    end
    alias printables labware

    def assign_library?
      false
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
    generate_tubes(purpose)
  end
end
