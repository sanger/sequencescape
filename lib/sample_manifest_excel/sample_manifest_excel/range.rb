module SampleManifestExcel

  class Range

  	attr_reader :options, :row, :position

    delegate :range, to: :position

  	def initialize(options, row)
  	  @options = options
      @row = row
      @position = Position.new(first_column: 1, last_column: options.length, first_row: row)
  	end

  end

end