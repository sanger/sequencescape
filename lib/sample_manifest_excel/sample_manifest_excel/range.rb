module SampleManifestExcel
  class NullRange
    ##
    # Always returns A1:A10.
    def reference
      'A1:A10'
    end

    ##
    # Always returns worksheet1!A1:A10
    def absolute_reference
      "worksheet1!#{reference}"
    end

    def ==(other)
      other.is_a?(self.class)
    end
  end

  ##
  # A range of cells signified by a reference.
  # The options are a range of text values which are used to validate a value.
  # The first row is the only mandatory field everything else can be inferred.
  # Each field that is not passed in the initializer is lazy loaded.
  class Range
    include Helpers::Attributes

    set_attributes :options, :first_row, :last_row, :first_column, :last_column, :worksheet_name, defaults: { first_column: 1, options: {} }

    attr_reader :first_cell, :last_cell, :reference, :absolute_reference

    ##
    # If the range is valid i.e. has a first row then a first cell and last cell are created
    # these are used for references.
    def initialize(attributes = {})
      super(default_attributes.merge(attributes))

      if valid?
        @first_cell = Cell.new(first_row, first_column)
        @last_cell = Cell.new(last_row, last_column)
      end
    end

    # If not defined and options are empty is set to first column.
    # If not defined and there are options is set to first column plus the
    # the number of options minus one.
    def last_column
      @last_column ||= if options.empty?
                         first_column
                       else
                         options.length + (first_column - 1)
                       end
    end

    ##
    # If not defined is set to the first row
    def last_row
      @last_row ||= first_row
    end

    ##
    # The reference for a range is a valid Excel reference e.g. $A$1:$H$10
    # Defined by the fixed reference of the first cell and the fixed reference
    # of the last cell.
    def reference
      "#{first_cell.reference}:#{last_cell.reference}"
    end

    def fixed_reference
      "#{first_cell.fixed}:#{last_cell.fixed}"
    end

    # rubocop:disable Rails/Delegate
    # Would change this to:
    # delegate :reference, to: :first_cell, prefix: true
    ##
    # The reference of the first cell.
    def first_cell_reference
      first_cell.reference
    end
    # rubocop:enable Rails/Delegate

    ##
    # An absolute reference is defined as a reference preceded by the name of the
    # worksheet to find a reference that is not in the current worksheet e.g. Sheet1!A1:A100
    # If the worksheet name is not present just returns the reference.
    def absolute_reference
      if worksheet_name.present?
        "#{worksheet_name}!#{fixed_reference}"
      else
        (fixed_reference).to_s
      end
    end

    ##
    # Set the worksheet name and return the range
    def set_worksheet_name(worksheet_name)
      self.worksheet_name = worksheet_name
      self
    end

    ##
    # A range is only valid if the first row is present.
    def valid?
      first_row.present?
    end

    ##
    # Return a list of references which are generally used together in other
    # classes of the module.
    def references
      {
        first_cell_reference: first_cell_reference,
        reference: reference,
        fixed_reference: fixed_reference,
        absolute_reference: absolute_reference
      }
    end

    def inspect
      "<#{self.class}: @options=#{options}, @first_row=#{first_row}, @last_row=#{last_row}, @first_column=#{first_column}, @last_column=#{last_column}, @worksheet_name=#{worksheet_name}>"
    end
  end
end
