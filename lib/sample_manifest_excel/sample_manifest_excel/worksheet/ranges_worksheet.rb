module SampleManifestExcel

	module Worksheet
	  class RangesWorksheet < Base

	  	def create_worksheet
	  		insert_axlsx_worksheet("Ranges")
	  		add_ranges
	  		ranges.set_absolute_references(name)
	  	end

	  	def add_ranges
    	  ranges.each { |k, range| add_row range.options }
    	  self
    	end

	  end
	end
end