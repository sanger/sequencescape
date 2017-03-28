module SampleManifestExcel
  class NullConfiguration
    def conditional_formattings
    end

    def columns
      NullColumns.new
    end

    def ranges
    end

    def manifest_types
    end

    def tag_group
    end

    def loaded?
      false
    end

    def present?
      false
    end

    def empty?
      true
    end

    class NullColumns
      def all
        NullColumnList.new
      end
    end
  end
end
