module SampleManifestExcel
  class NullValidation
    def range_name
      :null_range
    end

    def update(attributes = {})
    end

    def empty?
      true
    end

    def options
      {}
    end
  end
end