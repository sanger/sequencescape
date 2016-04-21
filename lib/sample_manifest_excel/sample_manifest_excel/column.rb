module SampleManifestExcel

  class Column

    include ActiveModel::Validations

    attr_accessor :name, :heading, :number, :type, :attribute, :validation, :value, :unlocked
    attr_reader :position

    validates_presence_of :name, :heading

    delegate :reference, to: :position

    delegate :range_name, to: :validation

    def initialize(attributes = {})
      default_attributes.merge(attributes).each do |name, value|
        send("#{name}=", value) unless name == :validation
        send("#{name}=", Validation.new(value)) if name == :validation 
      end
    end

    def attribute?
      attribute.present?
    end

    def validation?
      validation.present?
    end

    def unlocked?
      unlocked
    end

    def actual_value(object)
      attribute? ? attribute_value(object) : value
    end

    def attribute_value(object)
      attribute.values.first.call(object)
    end

    def set_validation(validation)
      self.validation = validation
      self
    end

    def set_formula1(range)
      validation.set_formula1(range)
    end

    def add_reference(first_row, last_row)
      @position = Position.new(first_column: number, first_row: first_row, last_row: last_row)
    end

    def set_number(number)
      self.number = number
      self
    end

  private

    def default_attributes
      {number: 0, type: :string}
    end
   
  end

end