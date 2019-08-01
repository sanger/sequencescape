# This module is very similar to SampleManifest::MultiplexedLibraryBehaviour
# Differences are:
#   (1)this module does not have methods needed for 'old' upload
#   (2)this module does not creat multiplexed library tube and respective requests
# Probably it should be cleaned at some point (20/04/2017)
module SampleManifest::LibraryBehaviour
  class Core
    attr_reader :tubes

    def initialize(manifest)
      @manifest = manifest
      @tubes = []
    end

    delegate :samples, to: :@manifest
    delegate :generate_library, to: :@manifest
    delegate :samples, :sample_manifest_assets, to: :@manifest

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

    def generate
      @tubes = generate_library
    end

    def generate_sample_and_aliquot(sanger_sample_id, tube)
      @manifest.tube_sample_creation(sanger_sample_id, tube)
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

    def labware_from_samples
      samples.map { |sample| sample.primary_receptacle.labware }
    end

    def labware
      tubes | labware_from_samples | @manifest.assets.map(&:labware)
    end
    alias printables labware

    def acceptable_purposes
      Purpose.none
    end

    def default_purpose
      Tube::Purpose.standard_library_tube
    end

    def included_resources
      [{ sample: :sample_metadata, asset: %i[barcodes aliquots] }]
    end
  end

  def generate_library
    generate_tubes(Tube::Purpose.standard_library_tube)
  end
end
