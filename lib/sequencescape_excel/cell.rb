# frozen_string_literal: true

module SequencescapeExcel
  ##
  # Holds the reference of a cell in an Excel spreadsheet based on its x (row) and y (column) position.
  class Cell
    attr_reader :row, :column

    ##
    # x and y position are required.
    # The row is held as is.
    # The column is converted to an alphanumberic character e.g 1 = "A", 27 = "AA"
    def initialize(x_row, y_col)
      @row = x_row
      @column = to_alpha(y_col)
    end

    ##
    # The column and the row which defines the reference e.g. "A1"
    def reference
      @reference ||= "#{column}#{row}"
    end

    ##
    # Also known as absolute reference. Used in Excel to ensure the reference does not
    # change when copied or filled. Particularly useful for applying ranges.
    # Designated by the addition of a dollar sign ($) e.g. $A$1
    def fixed
      @fixed ||= "$#{column}$#{row}"
    end

    ##
    # Two cells are comparable if their row and column are the same.
    def ==(other)
      return false unless other.is_a?(self.class)

      row == other.row && column == other.column
    end

    def inspect
      "<#{self.class}: @row=#{row}, @column=#{column}>"
    end

    private

    def to_alpha(num)
      (num - 1) < 26 ? (((num - 1) % 26) + 65).chr : (((num - 1) / 26) + 64).chr + (((num - 1) % 26) + 65).chr
    end
  end
end
