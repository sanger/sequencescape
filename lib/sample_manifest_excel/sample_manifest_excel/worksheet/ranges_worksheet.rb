module SampleManifestExcel

	module Worksheet
	  class RangesWorksheet < Base

	  	def create_worksheet
	  		add_ranges
	  	end

	  	def add_ranges
    	  ranges.each { |k, range| add_row range.options }
    	  self
    	end

	  end
	end
end