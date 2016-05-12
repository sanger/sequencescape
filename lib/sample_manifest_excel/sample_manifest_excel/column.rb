module SampleManifestExcel

  class Column

    include ActiveModel::Validations

    attr_accessor :name, :heading, :number, :type, :attribute, :validation, :value, :unlocked, :conditional_formatting_rules, :cf_options
    attr_reader :position

    validates_presence_of :name, :heading

    delegate :reference, to: :position
    delegate :first_cell_relative_reference, to: :position

    delegate :range_name, to: :validation

    def initialize(attributes = {})
      default_attributes.merge(attributes).each do |name, value|
        send("#{name}=", value)
      end
    end

    def validation=(validation)
      @validation = Validation.new(validation)
    end

    def conditional_formatting_rules=(conditional_formatting_rules)
      @conditional_formatting_rules = []
      conditional_formatting_rules.each do |rule|
        @conditional_formatting_rules << ConditionalFormattingRule.new(rule)
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

    def conditional_formatting_rules?
      conditional_formatting_rules.present?
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

    def add_validation_and_conditional_formatting(axlsx_worksheet)
      axlsx_worksheet.add_data_validation(reference, validation.options) if validation?
      axlsx_worksheet.add_conditional_formatting(reference, conditional_formatting_options) if conditional_formatting_rules?
    end

    def prepare_with(first_row, last_row, styles, ranges)
      add_reference(first_row, last_row)
      @unlocked = styles[:unlock].reference if unlocked?
      range = ranges.find_by(range_name) if validation?
      prepare_validation(range) if validation?
      prepare_conditional_formatting_rules(styles, range) if conditional_formatting_rules?
    end

    def add_reference(first_row, last_row)
      @position = Position.new(first_column: number, first_row: first_row, last_row: last_row)
    end

    def set_number(number)
      self.number = number
      self
    end

    def prepare_validation(range)
      validation.set_formula1(range)
    end

    def conditional_formatting_options
      conditional_formatting_rules.collect {|rule| rule.options}
    end

    def prepare_conditional_formatting_rules(styles, range=nil)
      conditional_formatting_rules.each do |rule|
        rule.prepare(styles[rule.style_name], first_cell_relative_reference, range)
      end
    end

  private

    def default_attributes
      {number: 0, type: :string, conditional_formatting_rules: []}
    end

  end

end