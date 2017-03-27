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

    class NullColumnList
      def extract(_headings)
        NullColumnList.new
      end

      def find_by(_key, _value)
      end

      def find_by_or_null(_key, _value)
        NullColumn.new
      end

      def valid?
        false
      end

      def errors
        {
          columns: 'Not valid'
        }
      end
    end

  end
end
