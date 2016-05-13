module SampleManifestExcel

  #Column creates a particular column with all the information about this column (name, heading,
  #value, type, attribute, should it be locked or unlocked, position of the column,
  #validation, conditional formatting rules)

  class Column

    include ActiveModel::Validations

    attr_accessor :name, :heading, :number, :type, :attribute, :validation, :value, :unlocked, :conditional_formatting_rules, :conditional_formatting_options
    attr_reader :position

    validates_presence_of :name, :heading

    delegate :reference, to: :position
    delegate :first_cell_relative_reference, to: :position

    delegate :range_name, to: :validation

    #To create a column a hash of arguments is required, name and heading attributes are mandatory
    #Other arguments can include unlocked, validation, conditional_formatting_rules, etc.

    def initialize(attributes = {})
      default_attributes.merge(attributes).each do |name, value|
        send("#{name}=", value)
      end
    end

    #Assignes validation to a column. Validation is an object.

    def validation=(validation)
      @validation = Validation.new(validation)
    end

    #Assignes conditional formatting rules to a column.
    #As column may have more than one conditional formatting rule, it returns a hash of
    #conditional formatting rule objects

    def conditional_formatting_rules=(conditional_formatting_rules)
      @conditional_formatting_rules = []
      conditional_formatting_rules.each do |rule|
        @conditional_formatting_rules << ConditionalFormattingRule.new(rule)
      end
    end

    #Checks if a column has an attribute

    def attribute?
      attribute.present?
    end

    #Checks if a column has a validation

    def validation?
      validation.present?
    end

    #Checks if a column should be unlocked

    def unlocked?
      unlocked
    end

    #check if column has conditional formatting rules

    def conditional_formatting_rules?
      conditional_formatting_rules.present?
    end

    #Returns an actual value for a column

    def actual_value(object)
      attribute? ? attribute_value(object) : value
    end

    #Returns a value based on collumn's attribute (when the value is dynamic (different for different cells))

    def attribute_value(object)
      attribute.values.first.call(object)
    end

    #Prepares a column to be used on a worksheet:
    #- adds reference to a column (i.e. $A$10:$A$15) to be used to place validation and
    #  conditional formatting on a worksheet,
    #- applies unlock style to a column, to unlock the column if required
    #- prepares validation to be used on a worksheet (updates validation formula with
    #  reference to a required range)
    #- prepares conditional formatting rules to be used on worksheet (updates conditional
    #  formatting rule with style to be applied (red or blue color), updates conditional
    #  formatting rule formula with column first cell reference(to indicate to which cells
    #  the rule should be applied), and also with range reference)
    #All arguments are worksheet attributes. Also see DataWorksheet#prepare_columns

    def prepare_with(first_row, last_row, styles, ranges)
      add_reference(first_row, last_row)
      @unlocked = styles[:unlock].reference if unlocked?
      range = ranges.find_by(range_name) if validation?
      prepare_validation(range) if validation?
      prepare_conditional_formatting_rules(styles, range) if conditional_formatting_rules?
    end

    #Adds reference to a column (i.e. $A$10:$A$15)

    def add_reference(first_row, last_row)
      @position = Position.new(first_column: number, first_row: first_row, last_row: last_row)
    end

    #Sets column number

    def set_number(number)
      self.number = number
      self
    end

    #Prepares validation to be used on a worksheet

    def prepare_validation(range)
      validation.set_formula1(range)
    end

    #Extracts conditional formatting rules options from all conditional formatting
    #rules of this column, for easier use in axlsx #add_conditional_formatting method

    def conditional_formatting_options
      conditional_formatting_rules.collect {|rule| rule.options}
    end

    #Updates all conditional formatting rules with the right style and the right formula

    def prepare_conditional_formatting_rules(styles, range=nil)
      conditional_formatting_rules.each do |rule|
        rule.prepare(styles[rule.style_name], first_cell_relative_reference, range)
      end
    end

    #Receives axlsx_worksheet as an argument and adds data validations and conditional
    #formattings for this column on this axlsx_worksheet

    def add_validation_and_conditional_formatting(axlsx_worksheet)
      axlsx_worksheet.add_data_validation(reference, validation.options) if validation?
      axlsx_worksheet.add_conditional_formatting(reference, conditional_formatting_options) if conditional_formatting_rules?
    end

  private

    def default_attributes
      {number: 0, type: :string, conditional_formatting_rules: []}
    end

  end

end