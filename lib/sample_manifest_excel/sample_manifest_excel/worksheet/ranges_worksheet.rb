module SampleManifestExcel

	module Worksheet
	  class RangesWorksheet < Base

	  	#Using axlsx worksheet creates worksheet with all the ranges listed on worksheet.
	  	#Also updates ranges with absolute reference (adds worksheet name to ranges references),
	  	#so that the ranges could be passed in and used in data worksheet (data validations and
	  	#conditional formattings use ranges absolute references in formulas).

	  	def create_worksheet
	  		insert_axlsx_worksheet("Ranges")
	  		add_ranges
	  		ranges.set_absolute_references(name)
	  	end

	  	#Adds ranges on the worksheet. One range one row.

	  	def add_ranges
    	  ranges.each { |k, range| add_row range.options }
    	  self
    	end

	  end
	end
end