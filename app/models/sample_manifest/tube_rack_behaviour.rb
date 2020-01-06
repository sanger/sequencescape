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

    # when uploading the manifest, this specifies which resources are queried and stored in the Cache
    # accessed through sample_manifest.sample_manifest_assets.includes(<resources below>)
    def included_resources
      [{ sample: :sample_metadata, asset: %i[labware aliquots barcodes] }]
    end
  end
end
