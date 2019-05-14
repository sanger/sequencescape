# frozen_string_literal: true

# SampleManifest::LongReadBehaviour
module SampleManifest::LongReadBehaviour
  # ClassMethods
  module ClassMethods
  end

  # Core
  class Core
    include SampleManifest::CoreBehaviour::NoSpecializedValidation

    attr_reader :tubes

    delegate :generate_long_read_tubes, to: :@manifest
    delegate :samples, :sample_manifest_assets, to: :@manifest

    def initialize(manifest)
      @manifest = manifest
      @tubes = []
    end

    def generate
      @tubes = generate_long_read_tubes
    end

    def generate_sample_and_aliquot(sanger_sample_id, tube)
      sample = @manifest.build_sample_and_aliquot(sanger_sample_id, tube)
      tube.register_stock!
      sample
    end

    def io_samples
      samples.map do |sample|
        {
          sample: sample,
          container: {
            barcode: sample.primary_receptacle.human_barcode
          }
        }
      end
    end

    def acceptable_purposes
      Purpose.none
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

    def validate_sample_container(sample, row)
      manifest_barcode = row['SANGER TUBE ID']
      primary_barcode = sample.primary_receptacle.human_barcode
      return if primary_barcode == manifest_barcode

      yield("You cannot move samples between tubes or modify their barcodes: #{sample.sanger_sample_id} should be in '#{primary_barcode}' but the manifest is trying to put it in '#{manifest_barcode}'")
    end

    def labware_from_samples
      samples.map { |sample| sample.assets.first }
    end

    def labware=(labware)
      @tubes = labware
    end

    def labware
      tubes | labware_from_samples | @manifest.assets
    end
    alias printables labware

    def assign_library?
      false
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

  def generate_long_read_tubes
    generate_tubes(Tube::Purpose.find_by(name: asset_type))
  end
end
