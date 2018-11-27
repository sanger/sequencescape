# This module is very similar to SampleManifest::MultiplexedLibraryBehaviour
# Differences are:
#   (1)this module does not have methods needed for 'old' upload
#   (2)this module does not creat multiplexed library tube and respective requests
# Probably it should be cleaned at some point (20/04/2017)
module SampleManifest::LibraryBehaviour
  module ClassMethods
    def create_for_library!(attributes, *args, &block)
      create!(attributes.merge(asset_type: 'library'), *args, &block).tap do |manifest|
        manifest.generate
      end
    end
  end

  class Core
    attr_reader :tubes

    def initialize(manifest)
      @manifest = manifest
      @tubes = []
    end

    delegate :samples, to: :@manifest
    delegate :generate_library, to: :@manifest

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
      @manifest.build_sample_and_aliquot(sanger_sample_id, tube)
    end

    def updated_by!(user, samples)
      # Does nothing at the moment
    end

    def details
      samples.each do |sample|
        yield({
          barcode: sample.assets.first.human_barcode,
          sample_id: sample.sanger_sample_id
        })
      end
    end

    def details_array
      [].tap do |details|
        samples.each do |sample|
          details << {
            barcode: sample.assets.first.human_barcode,
            sample_id: sample.sanger_sample_id
          }
        end
      end
    end

    def assign_library?
      true
    end

    def labware_from_samples
      samples.map { |sample| sample.assets.first }
    end

    def labware
      labware_from_samples | tubes
    end
    alias printables labware

    def acceptable_purposes
      Purpose.none
    end
  end

  RapidCore = Core

  def self.included(base)
    base.class_eval do
      extend ClassMethods
    end
  end

  def generate_library
    generate_tubes(Tube::Purpose.standard_library_tube)
  end
end
