module SampleManifestExcel
  module SpecialisedFields
    class Base

      include ActiveModel::Validations

      attr_reader :value, :row


      def good?(row)
        @row = row
        @value = row.value(key)
        valid?
      end

      def key
        @key ||= self.class.to_s.demodulize.underscore.to_sym
      end

      def value_present?
        value.present?
      end

    end
  end
end