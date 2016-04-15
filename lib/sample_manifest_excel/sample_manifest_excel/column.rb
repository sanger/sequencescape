module SampleManifestExcel

  class Column

    include ActiveModel::Validations

    include Position

    attr_accessor :name, :heading, :position, :type, :attribute, :validation, :value, :unlocked
    attr_reader :first_cell, :last_cell, :range

    validates_presence_of :name, :heading

    def initialize(attributes = {})
      default_attributes.merge(attributes).each do |name, value|
        send("#{name}=", value)
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

    def position_alpha
      return if position == 0
      to_alpha(position)
    end

    def add_range(first_row, last_row)
      @first_cell = "#{position_alpha}#{first_row}"
      @last_cell = "#{position_alpha}#{last_row}"
      @range = "#{first_cell}:#{last_cell}"
    end

  private

    def default_attributes
      {position: 0, type: :string, value: ""}
    end
   
  end

end