module SampleManifestExcel

  ##
  # Column creates a particular column with all the information about this column (name, heading,
  # value, type, attribute, should it be locked or unlocked, position of the column,
  # validation, conditional formatting rules)
  # A column is only valid if it has a name and heading.
  class Column

    include HashAttributes
    include ActiveModel::Validations

    set_attributes :name, :heading, :number, :type, :validation, :value, :unlocked, :conditional_formattings, 
                    defaults: {number: 0, type: :string, conditional_formattings: {}}

    attr_reader :range

    validates_presence_of :name, :heading

    delegate :range_name, to: :validation

    def initialize(attributes = {})
      create_attributes(attributes)

      @attribute = Attributes.find(name) if valid?
    end

    ##
    # If argument is a validation object copy it otherwise
    # create a new validation object
    def validation=(validation)
      @validation = if validation.kind_of?(Hash)
        Validation.new(validation)
      else
        validation.dup
      end
    end

    ##
    # If argument is a conditional formatting list copy it
    # otherwise create a new conditional formatting list
    def conditional_formattings=(conditional_formattings)
      @conditional_formattings = if conditional_formattings.kind_of?(Hash)
        ConditionalFormattingList.new(conditional_formattings)
      else
        conditional_formattings.dup
      end
    end

    ##
    # Creates a new Range object.
    def range=(attributes)
      @range = unless attributes.empty?
        Range.new(attributes)
      else
        NullRange.new
      end
    end

    ##
    # Some columns need to be unlocked so data can be entered.
    def unlocked?
      unlocked
    end

    ##
    # Some columns relate to a specific value. If that is null we return the column value.
    def attribute_value(sample)
      attribute.value(sample) || value
    end

    ##
    # Defaults to a NullValidation object
    def validation
      @validation || NullValidation.new
    end

    ##
    # Check whether a column has been updated with all of the references, validations etc.
    def updated?
      @updated
    end

    ##
    # Create a column range based on the first column, first row and last low
    # If the column has a validation range return it or return a NullRange.
    # Update the column validation using the passed worksheet and found range.
    # Update the conditional formatting based on a range and worksheet.
    def update(first_row, last_row, ranges, worksheet)
      self.range = {first_column: number, first_row: first_row, last_row: last_row}

      range = ranges.find_by(range_name)  || NullRange.new
      validation.update(range: range, reference: range.reference, worksheet: worksheet)

      conditional_formattings.update(self.range.references.merge(absolute_reference: range.absolute_reference, worksheet: worksheet))

      @updated = true

      self
    end

    ##
    # Set the column number and return the column
    def set_number(number)
      self.number = number
      self
    end

    def ==(other)
      return false unless other.is_a?(self.class) 
      name == other.name &&
      heading == other.heading &&
      number == other.number &&
      type == other.type &&
      validation == other.validation &&
      value == other.value &&
      unlocked == other.unlocked &&
      conditional_formattings == other.conditional_formattings
    end

    def initialize_dup(source)
      self.range = {}
      self.validation = source.validation
      self.conditional_formattings = source.conditional_formattings
      super
    end

  private

    attr_reader :attribute

  end

end