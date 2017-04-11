module SampleManifestExcel
  ##
  # Applied to conditional formatting to highlight important information in a spreadsheet.
  # Used where built in formulae don't do the job.
  # There are four types of special formulae:
  # - ISTEXT - checks whether each value in the cell for a column is a text value.
  # - ISNUMBER - checks whether each value in the cell for a column is a number.
  # - LEN - checks how long each value in the cell for a column is depending on the operator and operand.
  # - ISERROR - check whether each value in the cell for a column is within a range defined by the absolute reference of that range.
  class Formula
    include HashAttributes

    set_attributes :type, :first_cell_reference, :absolute_reference, :operator, :operand, defaults: { type: :len, operator: '>', operand: 999 }

    def initialize(attributes = {})
      create_attributes(attributes)
    end

    def update(attributes = {})
      update_attributes(attributes)
      self
    end

    def type=(type)
      @type = type.to_sym
    end

    ##
    # Returns a string representation of the formula.
    def to_s
      case type
      when :is_text
        "ISTEXT(#{first_cell_reference})"
      when :is_number
        "ISNUMBER(#{first_cell_reference})"
      when :len
        "LEN(#{first_cell_reference})#{operator}#{operand}"
      when :is_error
        "AND(NOT(ISBLANK(#{first_cell_reference})),ISERROR(MATCH(#{first_cell_reference},#{absolute_reference},0)>0))"
      end
    end

    def to_h
      {
        type: type,
        first_cell_reference: first_cell_reference,
        absolute_reference: absolute_reference,
        operator: operator,
        operand: operand
      }
    end
  end
end
