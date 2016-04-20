module SampleManifestExcel

  class ValidationRangeWorksheet

  	attr_reader :axlsx_worksheet, :rangeList
  	
  	def initialize(rangeList, axlsx_worksheet)
  	  @axlsx_worksheet = axlsx_worksheet
  	  @rangeList = rangeList
  	  add_ranges_to_worksheet
  	end

  	def add_ranges_to_worksheet
  	  rangeList.each do |k, range|
  	    axlsx_worksheet.add_row range.options
  	  end
  	end
  	
  end
end