module SampleManifest::MultiplexedLibraryBehaviour
  class Core
    # for #multiplexed_library_tube
    MxLibraryTubeException = Class.new(ActiveRecord::RecordNotFound)

    attr_accessor :library_tubes

    def initialize(manifest)
      @manifest = manifest
    end

    delegate :generate_mx_library, to: :@manifest
    delegate :study, to: :@manifest
    delegate :samples, to: :@manifest
    delegate :sample_manifest_assets, to: :@manifest

    def generate
      @mx_tube = generate_mx_library
    end

    def generate_sample_and_aliquot(sanger_sample_id, tube)
      @manifest.build_sample_and_aliquot(sanger_sample_id, tube)
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
      @mx_tube ||= (mx_tube_from_sample || mx_tube_from_manifest_asset)
    end

    def mx_tube_from_sample
      samples.first&.primary_receptacle&.requests&.first&.target_asset
    end

    def mx_tube_from_manifest_asset
      @manifest.assets.first&.requests&.first&.target_asset
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
      multiplexed_library_tube
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

    def assign_library?
      true
    end

    def included_resources
      [{ sample: :sample_metadata, asset: [:barcodes, :aliquots, { requests: :target_asset }] }]
    end
  end

  RapidCore = Core

  def generate_mx_library
    @library_tubes = generate_tubes(Tube::Purpose.standard_library_tube)
    Tube::Purpose.standard_mx_tube.create!.tap do |mx_tube|
      RequestFactory.create_external_multiplexed_library_creation_requests(@library_tubes, mx_tube, study)
    end
  end
end
