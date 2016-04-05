module SampleManifestExcel

  class Column

    include ActiveModel::Validations

    attr_accessor :name, :heading, :position, :type, :attribute, :validation, :value

    validates_presence_of :name, :heading

    def initialize(attributes = {})
      attributes.each do |name, value|
        send("#{name}=", value)
      end
    end

    def position
      @position ||= 0
    end

    def type
      @type ||= :string
    end

    def attribute?
      attribute.present?
    end

    def validation?
      validation.present?
    end

    def value
      @value ||= ""
    end

    def actual_value(object)
      attribute? ? attribute_value(object) : value
    end

    def validation=(validation)
      @validation = Axlsx::DataValidation.new(validation)
    end

    def attribute_value(object)
      attribute.values.first.call(object)
    end

    def set_position(position)
      self.position = position
      self
    end
   
  end

end