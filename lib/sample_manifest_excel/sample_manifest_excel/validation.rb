module SampleManifestExcel

  class Validation

    attr_accessor :options, :range_name

    def initialize(attributes = {})
      attributes.each do |name, value|
        send("#{name}=", value)
      end
    end

    def set_formula1(range)
      return unless range_required?
      options[:formula1] = range.absolute_reference
    end

    def range_required?
      range_name.presence
    end

    def valid?
      options
    end
  end

end