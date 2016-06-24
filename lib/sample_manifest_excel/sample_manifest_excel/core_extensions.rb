module SampleManifestExcel

  ##
  # Core Extensions provide extensions to standard classes
  # which can be included whenever needed.
  module CoreExtensions
    module Hash

      ##
      # Example:
      #  {a: {}, b: {}, c: { a: nil, b: nil, c: {a: 1, b: 2}} }.combine_by_key(
      #  {a: {b: 1}, b: {c: 2}, c: {c:3, d: 4}}, :c) 
      #   =>
      #  {a: {}, b: {}, c: { a: {b: 1}, b: {c: 2}, c: {a: 1, b: 2, c:3, d: 4}} }
      def combine_by_key(other, key)
        if self[key].present?
          self[key].deep_merge!(other.slice(*self[key].keys)) do |k, this_value, other_value|
            if this_val.nil?
              other_val
            else
              this.val.merge!(other_value)
            end
          end
        end
        self
      end
    end

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