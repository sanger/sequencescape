module SampleManifestExcel

  class Range

  	attr_reader :options, :row, :position, :absolute_reference

    delegate :reference, to: :position

  	def initialize(options, row)
  	  @options = options
      @row = row
      @position = Position.new(first_column: 1, last_column: options.length, first_row: row)
  	end

    def set_absolute_reference(worksheet)
      @absolute_reference = "#{worksheet.name}!#{reference}"
      self
    end

    def valid?
      options && row && position
    end

  end

end