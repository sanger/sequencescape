module SampleManifestExcel

  ##
  # A null object for validations.
  class NullValidation

    ##
    # Always returns :null range
    def range_name
      :null_range
    end

    ##
    # Does nothing
    def update(attributes = {})
    end

    ##
    # A null validation is always empty.
    def empty?
      true
    end

    ##
    # Always returns an empty hash.
    def options
      {}
    end

    def ==(other)
      other.is_a?(self.class)
    end
  end
end