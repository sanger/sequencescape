# frozen_string_literal: true

module Heron
  module Factories
    #
    # Factory class to generate sample tubes inside a Heron rack
    class Tube
      include ActiveModel::Model
      include Concerns::ForeignBarcodes

      attr_accessor :supplier_sample_id, :sample, :sample_tube, :study

      validates_presence_of :supplier_sample_id, :study

      ##
      # Persists the material including the associated container
      def create
        return unless valid?

        @sample = create_sample!

        @sample_tube = SampleTube.create! do |sample_tube|
          sample_tube.aliquots.new(sample: @sample, study: study)
        end
        create_tube_barcode!(@sample_tube)

        @sample_tube
      end

      def create_tube_barcode!(sample_tube)
        # TODO: the below foreign barcode checks are duplicated in sanger_tube_id specialised field file - refactor
        Barcode.create!(asset_id: sample_tube.id, barcode: barcode, format: barcode_format)
      end

      def create_sanger_sample_id!
        SangerSampleId.generate_sanger_sample_id!(study.abbreviation)
      end

      def create_sample!
        sanger_sample_id = create_sanger_sample_id!
        ::Sample.create!(
          name: sanger_sample_id,
          sanger_sample_id: sanger_sample_id
        ) do |sample|
          sample.sample_metadata.update!(
            supplier_name: supplier_sample_id
          )
          sample.studies << study
        end
      end
    end
  end
end
