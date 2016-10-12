module SampleManifestExcel

  module SampleField

    class Base
      include SpecialisedField

      def match?(sample)
        value == sample_value(sample)
      end

      def sample_value(sample)
      end
    end

    module SangerSampleIdValue
      def sample_value(sample)
        sample.sanger_sample_id
      end
    end

    Dir[File.join(File.dirname(__FILE__),"sample_field","*.rb")].each  { |file| require file }

    SpecialisedField.create_field_list(self)

  end

end