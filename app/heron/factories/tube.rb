module Heron
  module Factories
    class Tube
      include ActiveModel::Model
      attr_accessor :location, :barcode, :supplier_sample_id, :sample, :sample_tube, :study

      validates_presence_of :location, :barcode, :supplier_sample_id, :study

      ##
      # Persists the material including the associated container
      def create
        return unless valid?

        @sample = create_sample!

        @sample_tube = SampleTube.create!

        @sample_tube.aliquots.create(sample: @sample, study: study)

        barcode_instance = Barcode.create!(barcode: barcode, format: 'fluidx_barcode',
          asset: @sample_tube)

        @sample_tube
      end

      def create_sample!
        sanger_sample_id = SangerSampleId.generate_sanger_sample_id!(study.abbreviation)
        @sample = Sample.create!(
          sanger_sample_id: sanger_sample_id,
          name: supplier_sample_id
        )
        @sample.sample_metadata.update_attributes!(
          sample_public_name: supplier_sample_id,
          supplier_name: supplier_sample_id
        )
        #@sample.create_uuid_object! #(external_id: @sample.id)
        @sample.studies << study if study && !sample.studies.include?(study)
        @sample
      end
    end
  end
end
