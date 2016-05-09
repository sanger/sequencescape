module SampleManifestExcel

  class Column

    attr_accessor :position
    attr_reader :heading, :validation, :attribute

    def initialize(attributes)
      @position = attributes[:position] || 0
      @heading = attributes[:heading]
      @validation = attributes[:validation]
      @attribute = attributes[:attribute]
    end

    def has_attribute?
      attribute.present?
    end

    def has_validation?
      validation.present?
    end
   
  end

end