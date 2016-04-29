module SampleManifestExcel

	class ConditionalFormattingRule

    attr_reader :options

		def initialize(options)
			@options = options
		end

    def set_style(style)
      options['dxfId'] = style.reference if has_style? && style_not_set?
    end

    def set_first_cell_in_formula(first_cell_relative_reference)
      options['formula'].sub!('first_cell_relative_reference', first_cell_relative_reference) if has_formula?
    end

    def set_range_reference_in_formula(range)
      options['formula'].sub!('range_absolute_reference', range.absolute_reference) if has_formula?
    end

    private

    def has_style?
      options['dxfId']
    end

    def has_formula?
      options['formula']
    end

    def style_not_set?
      options['dxfId'].is_a?(Symbol)
    end

	end
end