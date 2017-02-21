module SampleManifestExcel
  module SampleField
    class SangerPlateId < Base
      def sample_value(sample)
        sample.wells.first.plate.sanger_human_barcode
      end
    end
  end
end
