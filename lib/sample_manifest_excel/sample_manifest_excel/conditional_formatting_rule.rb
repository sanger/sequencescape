module SampleManifestExcel

	class ConditionalFormattingRule

    attr_reader :options

		def initialize(options)
			@options = options
		end

    def set_style(style)
      options['dxfId'] = style.reference if options['dxfId']
    end

    def set_first_cell_in_formula(first_cell_relative_reference)
      options['formula'].sub!('first_cell_relative_reference', first_cell_relative_reference) if options['formula']
    end

    def set_range_reference_in_formula(range)
      options['formula'].sub!('range_absolute_reference', range.absolute_reference) if options['formula']
    end

	end
end