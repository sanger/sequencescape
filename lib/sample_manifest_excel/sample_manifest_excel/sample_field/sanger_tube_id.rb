module SampleManifestExcel
  module SampleField
    class SangerTubeId < Base
      def sample_value(sample)
        sample.assets.first.sanger_human_barcode
      end
    end
  end
end
