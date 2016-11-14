module SampleManifestExcel

  ##
  # A range of cells signified by a reference.
  # The options are a range of text values which are used to validate a value.
  # The first row is the only mandatory field everything else can be inferred.
  # Each field that is not passed in the initializer is lazy loaded.
  class Range

    include HashAttributes

    set_attributes :options, :first_row, :last_row, :first_column, :last_column, :worksheet_name

    attr_reader :first_cell, :last_cell, :reference, :absolute_reference

    ##
    # If the range is valid i.e. has a first row then a first cell and last cell are created
    # these are used for references.
    def initialize(attributes = {})
      create_attributes(attributes)

      @static = options.is_a?(Array)

      if valid?
        @first_cell = Cell.new(first_row, first_column)
        @last_cell = Cell.new(last_row, last_column) unless dynamic?
      end
    end

    # If not defined defaults to one.
    def first_column
      @first_column ||= 1
    end

    # If not defined and options are empty is set to first column.
    # If not defined and there are options is set to first column plus the
    # the number of options minus one.
    def last_column
      @last_column || if dynamic?
        calculate_last_column
      else
        @last_column = calculate_last_column
      end
    end

    # Returns either the cached last cell, or a dynamically created one.
    # We don't memoize this, as we dymanically recalculate the value
    # at runtime for some ranges. For static ranges the last_cell is
    # calculated in the initializer so will be available. Also
    # we can't just do @last_cell || Cell.new as @last_cell can be
    # legitimately falsey
    def last_cell
      dynamic? ? Cell.new(last_row, last_column) : @last_cell
    end

    ##
    # If not defined is set to the first row
    def last_row
      @last_row ||= first_row
    end

    ##
    # If not defined is set to an empty hash.
    def options
      @options ||= {}
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

    ##
    # The reference of the first cell.
    def first_cell_reference
      first_cell.reference
    end

    ##
    # An absolute reference is defined as a reference preceded by the name of the
    # worksheet to find a reference that is not in the current worksheet e.g. Sheet1!A1:A100
    # If the worksheet name is not present just returns the reference.
    def absolute_reference
      if worksheet_name.present?
        "#{worksheet_name}!#{fixed_reference}"
      else
        "#{fixed_reference}"
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
    # A dynamic rage uses a se of options that are calculated
    # at runtime. Such as a SampleManifestExcel::DynamicOption
    # Arrays are assumed to be static
    def dynamic?
      ! @static
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

    private

    def calculate_last_column
      if options.empty?
        first_column
      else
        options.length + (first_column - 1)
      end
    end

  end

end
