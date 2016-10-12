module SampleManifestExcel
  module SampleField
    class Well < Base
      def sample_value(sample)
        sample.wells.first.map.description
      end
    end
  end
end