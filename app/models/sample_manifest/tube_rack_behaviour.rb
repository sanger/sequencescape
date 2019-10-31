module SampleManifest::TubeRackBehaviour
  class Core < SampleManifest::SharedTubeBehaviour::Base
    include SampleManifest::CoreBehaviour::NoSpecializedValidation
    include SampleManifest::CoreBehaviour::StockAssets

    attr_reader :tubes

    def initialize(manifest)
      @manifest = manifest
      @tubes = []
    end

    def generate
      @tubes = generate_tube_racks(purpose, @manifest.tube_rack_purpose)
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
      Tube::Purpose.where(target_type: SampleTube)
    end

    def acceptable_rack_purposes
      TubeRack::Purpose.where(target_type: TubeRack)
    end

    def default_purpose
      Tube::Purpose.standard_sample_tube
    end

    def default_tube_rack_purpose
      TubeRack::Purpose.standard_tube_rack
    end

    def labware_from_samples
      samples.map { |s| s.primary_receptacle.labware }
    end

    def labware=(labware)
      @tubes = labware
    end

    def labware
      tubes | labware_from_samples | @manifest.assets.map(&:labware)
    end
    alias printables labware

    def included_resources
      [{ sample: :sample_metadata, asset: %i[aliquots barcodes] }]
    end
  end
end
