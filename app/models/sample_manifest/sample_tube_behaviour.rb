module SampleManifest::SampleTubeBehaviour
  module ClassMethods
    def create_for_sample_tube!(attributes, *args, &block)
      create!(attributes.merge(asset_type: '1dtube'), *args, &block).tap do |manifest|
        manifest.generate
      end
    end
  end

  class Core
    include SampleManifest::CoreBehaviour::NoSpecializedValidation

    attr_reader :tubes

    delegate :generate_1dtubes, to: :@manifest
    delegate :samples, to: :@manifest

    def initialize(manifest)
      @manifest = manifest
      @tubes = []
    end

    def generate
      @tubes = generate_1dtubes
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

    def validate_sample_container(sample, row)
      manifest_barcode, primary_barcode = row['SANGER TUBE ID'], sample.primary_receptacle.human_barcode
      return if primary_barcode == manifest_barcode

      yield("You cannot move samples between tubes or modify their barcodes: #{sample.sanger_sample_id} should be in '#{primary_barcode}' but the manifest is trying to put it in '#{manifest_barcode}'")
    end

    def labware_from_samples
      samples.map { |sample| sample.assets.first }
    end

    def labware
      labware_from_samples | tubes
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

  def generate_1dtubes
    generate_tubes(Tube::Purpose.standard_sample_tube)
  end
end
