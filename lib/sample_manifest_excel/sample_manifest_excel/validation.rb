module SampleManifestExcel

  class Validation

    attr_reader :options, :range_name

    def initialize(options, range_name)
      @options = options
      @range_name = range_name
    end

    def set_formula1(range)
      options[:formula1] = range.absolute_reference
    end

  end

end