module SampleManifestExcel

  class Style

    attr_reader :name, :options, :reference

  	def initialize (workbook, options)
  	  @options = options
  	  @reference = workbook.styles.add_style options
  	end

  	def valid?
  		reference && options
  	end

  end

end