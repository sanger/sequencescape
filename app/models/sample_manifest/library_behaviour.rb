# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2015 Genome Research Ltd.

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

  def sample_tube_sample_creation(samples_data, _study_id)
    study.samples << samples_data.map do |barcode, sanger_sample_id, _prefix|
      create_sample(sanger_sample_id).tap do |sample|
        sample_tube = LibraryTube.find_by(barcode: barcode) or raise ActiveRecord::RecordNotFound, "Cannot find library tube with barcode #{barcode.inspect}"
        sample_tube.aliquots.create!(sample: sample)
      end
    end
  end
  private :sample_tube_sample_creation
end
