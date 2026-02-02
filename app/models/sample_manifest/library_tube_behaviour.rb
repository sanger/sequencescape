# frozen_string_literal: true

# This module is very similar to SampleManifest::MultiplexedLibraryBehaviour
# Differences are:
#   (1)this module does not have methods needed for 'old' upload
#   (2)this module does not creat multiplexed library tube and respective requests
# Probably it should be cleaned at some point (20/04/2017)
module SampleManifest::LibraryTubeBehaviour
  # Behaviour for generating a library tube
  class Core < SampleManifest::SharedTubeBehaviour::Base
    include SampleManifest::CoreBehaviour::LibraryAssets

    attr_reader :tubes

    def initialize(manifest)
      @manifest = manifest
      @tubes = []
    end

    def generate
      @tubes = generate_tubes(Tube::Purpose.standard_library_tube)
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
end
