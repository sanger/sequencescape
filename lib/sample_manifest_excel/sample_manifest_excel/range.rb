module SampleManifestExcel

  class Range

    include HashAttributes

    set_attributes :options, :first_row, :last_row, :first_column, :last_column, :worksheet_name

    attr_reader :first_cell, :last_cell, :reference, :absolute_reference

    def initialize(attributes = {})
      create_attributes(attributes)

      if valid?
        @first_cell = Cell.new(first_row, first_column)
        @last_cell = Cell.new(last_row, last_column)
      end
    end

    def first_column
      @first_column ||= 1
    end

    def last_column
      @last_column ||= if options.empty?
        first_column
      else
        options.length
      end
    end

    def last_row
      @last_row ||= first_row
    end

    def options
      @options ||= {}
    end

    def reference
      @reference ||= "#{first_cell.fixed}:#{last_cell.fixed}"
    end

    def first_cell_relative_reference
      first_cell.reference
    end

    def absolute_reference
      @absolute_reference ||= if worksheet_name.present?
        "#{worksheet_name}!#{reference}"
      else
        "#{reference}"
      end
    end

    def set_worksheet_name(worksheet_name)
      self.worksheet_name = worksheet_name
      self
    end

    def valid?
      first_row.present?
    end

  end

end