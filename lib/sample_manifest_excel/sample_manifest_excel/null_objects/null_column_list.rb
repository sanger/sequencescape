module SampleManifestExcel
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

    def with_specialised_fields
      []
    end
  end
end
