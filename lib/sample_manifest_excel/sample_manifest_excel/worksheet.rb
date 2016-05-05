module SampleManifestExcel

  class Worksheet

  	attr_reader :axlsx_worksheet, :columns, :ranges

  	def initialize(attributes = {})
  	  @axlsx_worksheet = attributes[:axlsx_worksheet]
  	  @columns = attributes[:column_list]
  	  @ranges = attributes[:range_list]
  	end

  	def add_row(values = [], style = nil, types = nil)
			axlsx_worksheet.add_row values, types: types || [:string]*values.length, style: style
  	end

  	def add_rows(n)
      n.times { |i| add_row }
    end

  	def add_title_and_info(sample_manifest)
      add_row ["DNA Collections Form"]
      add_rows(3)
      add_row ["Study:", sample_manifest.study.abbreviation]
      add_row ["Supplier:", sample_manifest.supplier.name]
      add_row ["No. #{sample_manifest.asset_type.pluralize.capitalize} Sent:", sample_manifest.count]
      add_rows(1)
  	end

  	def add_ranges
  	  ranges.each do |k, range|
  	    add_row range.options
  	  end
  	end

  end

end