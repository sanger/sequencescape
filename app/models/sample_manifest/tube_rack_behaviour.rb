# frozen_string_literal: true

module SampleManifest::TubeRackBehaviour
  # Specifies behaviour for generation of Tube Rack Manifests
  # Ends up being included in SampleManifest model because is instantiated in CoreBehaviour
  class Core < SampleManifest::SharedTubeBehaviour::Base
    include SampleManifest::CoreBehaviour::NoSpecializedValidation
    include SampleManifest::CoreBehaviour::StockAssets

    attr_reader :tubes

    def initialize(manifest)
      @manifest = manifest
      @tubes = []
    end

    def generate
      desired_number_of_tubes = count * @manifest.tube_rack_purpose.size
      @tubes = generate_tubes(purpose, desired_number_of_tubes)
    end

    # This was copied from sample_tube_behaviour.rb, commented out until needed
    # def io_samples
    #   samples.map do |sample|
    #     {
    #       sample: sample,
    #       container: {
    #         barcode: sample.primary_receptacle.human_barcode
    #       }
    #     }
    #   end
    # end

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

  # This was copied from sample_tube_behaviour.rb, commented out until needed
  #   def labware_from_samples
  #     samples.map { |s| s.primary_receptacle.labware }
  #   end

  #   def labware=(labware)
  #     @tubes = labware
  #   end

  #   def labware
  #     tubes | labware_from_samples | @manifest.assets.map(&:labware)
  #   end
  #   alias printables labware

  #   def included_resources
  #     [{ sample: :sample_metadata, asset: %i[aliquots barcodes] }]
  #   end
  end
end
