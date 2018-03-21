# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2015 Genome Research Ltd.

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
    def initialize(manifest)
      @manifest = manifest
    end

    delegate :samples, to: :@manifest
    delegate :generate_library, to: :@manifest

    def io_samples
      samples.map do |sample|
        {
          sample: sample,
          container: {
            barcode: sample.primary_receptacle.sanger_human_barcode
          },
          library_information: sample.primary_receptacle.library_information
        }
      end
    end

    def generate
      generate_library
    end

    def updated_by!(user, samples)
      # Does nothing at the moment
    end

    def details
      samples.each do |sample|
        yield({
          barcode: sample.assets.first.sanger_human_barcode,
          sample_id: sample.sanger_sample_id
        })
      end
    end

    def details_array
      [].tap do |details|
        samples.each do |sample|
          details << {
            barcode: sample.assets.first.sanger_human_barcode,
            sample_id: sample.sanger_sample_id
          }
        end
      end
    end

    def assign_library?
      true
    end

    def labware
      samples.map { |sample| sample.assets.first }
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
    tubes = generate_tubes(Tube::Purpose.standard_library_tube)
  end
end
