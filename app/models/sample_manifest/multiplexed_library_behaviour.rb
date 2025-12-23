# frozen_string_literal: true
module SampleManifest::MultiplexedLibraryBehaviour
  class Core < SampleManifest::SharedTubeBehaviour::Base
    include SampleManifest::CoreBehaviour::LibraryAssets

    # for #multiplexed_library_tube
    MxLibraryTubeException = Class.new(ActiveRecord::RecordNotFound)

    attr_accessor :library_tubes

    def initialize(manifest)
      @manifest = manifest
    end

    def generate
      @library_tubes = generate_tubes(Tube::Purpose.standard_library_tube)
      @mx_tube = generate_mx_library
    end

    def generate_mx_library
      Tube::Purpose.standard_mx_tube.create!.tap do |mx_tube|
        RequestFactory.create_external_multiplexed_library_creation_requests(@library_tubes, mx_tube, study)
      end
    end

    def io_samples
      samples.map do |sample|
        {
          sample: sample,
          container: {
            barcode: sample.primary_receptacle.human_barcode
          },
          library_information: sample.primary_receptacle.library_information
        }
      end
    end

    def acceptable_purposes
      Purpose.none
    end

    def default_purpose
      Tube::Purpose.standard_library_tube
    end

    def multiplexed_library_tube
      mx_tube || raise(MxLibraryTubeException.new, 'Mx tube not found')
    end

    def mx_tube
      @mx_tube ||= mx_tube_from_manifest_asset
    end

    def mx_tube_from_manifest_asset
      @manifest.assets.first&.external_library_creation_requests&.first&.target_asset # rubocop:disable Style/SafeNavigationChainLength
    end

    def pending_external_library_creation_requests
      multiplexed_library_tube.requests_as_target.for_state('pending')
    end

    def labware=(labware)
      raise ArgumentError, 'labware should contain only one element' if labware.count > 1

      @mx_tube = labware.first
    end

    def labware
      [multiplexed_library_tube]
    end

    def printables
      multiplexed_library_tube.labware
    end

    def included_resources
      [{ sample: :sample_metadata, asset: [:barcodes, :aliquots, { requests: :target_asset }] }]
    end

    def stocks?
      true
    end
  end
end
