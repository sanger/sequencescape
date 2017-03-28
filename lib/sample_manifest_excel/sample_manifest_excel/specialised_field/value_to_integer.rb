module SampleManifestExcel
  module SpecialisedField
    module ValueToInteger
      def value=(value)
        @value = value.to_i if value.present?
      end
    end
  end
end
