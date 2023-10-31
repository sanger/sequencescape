# frozen_string_literal: true

module SequencescapeExcel
  ##
  # A range of cells signified by a reference.
  # The options are a range of text values which are used to validate a value.
  # The first row is the only mandatory field everything else can be inferred.
  # Each field that is not passed in the initializer is lazy loaded.
  class Range
    include Helpers::Attributes

    setup_attributes :options,
                     :identifier,
                     :name,
                     :scope,
                     :first_row,
                     :last_row,
                     :first_column,
                     :last_column,
                     :worksheet_name,
                     :scope_on,
                     defaults: {
                       first_column: 1,
                       options: []
                     }

    attr_reader :first_cell

    ##
    # If the range is valid i.e. has a first row then a first cell and last cell are created
    # these are used for references.
    def initialize(attributes = {})

      super(default_attributes.deep_merge(attributes.with_indifferent_access))

      return unless valid?

      @first_cell = Cell.new(first_row, first_column)
      @last_cell = Cell.new(last_row, last_column) unless dynamic?
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

    # If not defined is set to an empty hash.
    def options
      if static?
        @options
      elsif dynamic?
        create_dynamic_options
      else
        {}
      end
    end

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
      worksheet_name.present? ? "#{worksheet_name}!#{fixed_reference}" : fixed_reference.to_s
    end

    ##
    # Set the worksheet name and return the range
    def set_worksheet_name(worksheet_name) # rubocop:disable Naming/AccessorMethodName
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
    # at runtime. Such as a SequencescapeExcel::DynamicOption
    # Arrays are assumed to be static
    def dynamic?
      @identifier.present?
    end

    def static?
      @options.present?
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
      options.empty? ? first_column : options.length + (first_column - 1)
    end

    def create_dynamic_options
      klass.public_send(*Array(@scope)).pluck(@identifier)
    end

    def klass
      @klass ||= (@scope_on.presence || @name.classify).constantize
    end

    def inspect
      # rubocop:todo Layout/LineLength
      "<#{self.class}: @options=#{options}, @first_row=#{first_row}, @last_row=#{last_row}, @first_column=#{first_column}, @last_column=#{last_column}, @worksheet_name=#{worksheet_name}>"
      # rubocop:enable Layout/LineLength
    end
  end
end
