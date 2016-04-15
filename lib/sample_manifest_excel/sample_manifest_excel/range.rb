module SampleManifestExcel

  class Range

  	include Position

  	attr_accessor :name, :list_of_options, :position, :range_of_cells

  	def initialize(name, list_of_options=[])
  	  @name = name
  	  @list_of_options = list_of_options
  	end

  	def position
  	  @position ||= 0
  	end

    def add_range_of_cells(first_row=1, first_column=1)
      first_cell = "#{to_alpha(first_column)}#{position+first_row-1}"
      last_cell = "#{to_alpha(first_column+list_of_options.length-1)}#{position+first_row-1}"
      @range_of_cells = "#{first_cell}:#{last_cell}"
    end

  end

end