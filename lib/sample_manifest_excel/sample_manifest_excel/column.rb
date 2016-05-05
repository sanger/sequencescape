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

    def cf_rules?
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

    def cf_options
      conditional_formatting_rules.collect {|rule| rule.options}
    end

    def prepare_conditional_formatting_rules(styles, range=nil)
      conditional_formatting_rules.each do |rule|
        style_name = rule.options['dxfId']
        rule.set_style(styles[style_name])
        rule.set_first_cell_in_formula(first_cell_relative_reference)
        rule.set_range_reference_in_formula(range) if range
      end
    end

    def add_conditional_formatting_rules(cf_rules)
      conditional_formatting_rules.unshift cf_rules
    end

  private

    def default_attributes
      {number: 0, type: :string, conditional_formatting_rules: []}
    end

  end

end