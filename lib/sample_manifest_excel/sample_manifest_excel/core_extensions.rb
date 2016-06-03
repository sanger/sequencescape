module SampleManifestExcel
  module CoreExtensions
    module Hash
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
  end
end