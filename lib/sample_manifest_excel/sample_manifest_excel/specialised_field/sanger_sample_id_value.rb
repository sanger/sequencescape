module SampleManifestExcel
  module SpecialisedField
    module SangerSampleIdValue
      def value=(sample)
        @value = sample.sanger_sample_id
      end
    end
  end
end