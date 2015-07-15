#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2011,2012,2013 Genome Research Ltd.
module SampleManifest::SampleTubeBehaviour
  module ClassMethods
    def create_for_sample_tube!(attributes, *args, &block)
      create!(attributes.merge(:asset_type => '1dtube'), *args, &block).tap do |manifest|
        manifest.generate
      end
    end
  end

  class Core

    include SampleManifest::CoreBehaviour::NoSpecializedValidation

    def initialize(manifest)
      @manifest = manifest
    end

    delegate :generate_1dtubes, :to => :@manifest
    alias_method(:generate, :generate_1dtubes)

    delegate :samples, :to => :@manifest

    def io_samples
      samples.map do |sample|
        {
          :sample    => sample,
          :container => {
            :barcode => sample.primary_receptacle.sanger_human_barcode
          }
        }
      end
    end

    def print_labels(&block)
      printables = self.samples.map do |sample|
        sample_tube = sample.assets.first
        PrintBarcode::Label.new(
          :number => sample_tube.barcode,
          :study  => sample.sanger_sample_id,
          :prefix => sample_tube.prefix, :suffix => ""
        )
      end
      yield(printables, 'NT')
    end

    def updated_by!(user, samples)
      # Does nothing at the moment
    end

    def details(&block)
      samples.each do |sample|
        yield({
          :barcode   => sample.assets.first.sanger_human_barcode,
          :sample_id => sample.sanger_sample_id
        })
      end
    end

    def validate_sample_container(sample, row, &block)
      manifest_barcode, primary_barcode = row['SANGER TUBE ID'], sample.primary_receptacle.sanger_human_barcode
      return if primary_barcode == manifest_barcode
      yield("Tube info for #{sample.sanger_sample_id} mismatch: expected #{primary_barcode} but reported as #{manifest_barcode}")
    end

  end

  # There is no reason for this to need a rapid version as it should be reasonably
  # efficient in the first place.
  RapidCore = Core

  def self.included(base)
    base.class_eval do
      extend ClassMethods
    end
  end

  def generate_1dtubes
    generate_tubes(Tube::Purpose.standard_sample_tube)
  end

end
