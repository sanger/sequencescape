# frozen_string_literal: true

module SampleManifestExcel
  ##
  # Core Extensions provide extensions to standard classes
  # which can be included whenever needed.
  module CoreExtensions
    ##
    # Provides attribute readers for data validations and conditional formattings.
    module AxlsxWorksheet
      def data_validation_rules
        data_validations
      end

      def conditional_formatting_rules
        conditional_formattings
      end
    end
  end
end
