module SampleManifestExcel

  #Column creates a particular column with all the information about this column (name, heading,
  #value, type, attribute, should it be locked or unlocked, position of the column,
  #validation, conditional formatting rules)

  class Column

    include HashAttributes
    include ActiveModel::Validations

    set_attributes :name, :heading, :number, :type, :validation, :value, :unlocked, :conditional_formattings, 
                    defaults: {number: 0, type: :string, conditional_formattings: {}}

    attr_reader :range

    validates_presence_of :name, :heading

    delegate :reference, :first_cell_relative_reference, to: :range

    delegate :range_name, to: :validation

    #To create a column a hash of arguments is required, name and heading attributes are mandatory
    #Other arguments can include unlocked, validation, conditional_formatting_rules, etc.

    def initialize(attributes = {})
      create_attributes(attributes)

      @attribute = Attributes.find(name) if valid?
    end

    #Assigns validation to a column. Validation is an object.

    def validation=(validation)
      @validation = Validation.new(validation)
    end

    def conditional_formattings=(conditional_formattings)
      @conditional_formattings = ConditionalFormattingList.new(conditional_formattings)
    end

    def range=(attributes)
      @range = Range.new(attributes)
    end

    #Checks if a column should be unlocked

    def unlocked?
      unlocked
    end

    #Returns a value based on collumn's attribute (when the value is dynamic (different for different cells))

    def attribute_value(sample)
      attribute.value(sample) || value
    end

    def validation
      @validation || NullValidation.new
    end

    def updated?
      @updated
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

    def update(first_row, last_row, ranges, workbook)
      self.range = {first_column: number, first_row: first_row, last_row: last_row}

      range = ranges.find_by(range_name)  || NullRange.new
      validation.update(range: range)

      conditional_formattings.update(workbook: workbook, first_cell: first_cell_relative_reference, absolute_reference: range.reference)

      @updated = true

      self
    end

    #Adds reference to a column (i.e. $A$10:$A$15)

    def add_reference(first_row, last_row)
      @range = Range.new(first_column: number, first_row: first_row, last_row: last_row)
    end

    #Sets column number

    def set_number(number)
      self.number = number
      self
    end

    #Receives axlsx_worksheet as an argument and adds data validations and conditional
    #formattings for this column on this axlsx_worksheet

    def add_validation_and_conditional_formatting(axlsx_worksheet)
      axlsx_worksheet.add_data_validation(reference, validation.options) unless validation.empty?
      axlsx_worksheet.add_conditional_formatting(reference, conditional_formattings.options)
    end

  private

    attr_reader :attribute

  end

end