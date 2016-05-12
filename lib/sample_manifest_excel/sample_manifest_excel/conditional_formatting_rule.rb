module SampleManifestExcel

	class ConditionalFormattingRule

    attr_reader :options

		def initialize(options)
			@options = options
		end

    def prepare(style, first_cell_relative_reference, range)
      set_style(style)
      set_first_cell_in_formula(first_cell_relative_reference)
      set_range_reference_in_formula(range)
    end

    def set_style(style)
      options['dxfId'] = style.reference if has_style? && style_not_set?
    end

    def set_first_cell_in_formula(first_cell_relative_reference)
      options['formula'].sub!('first_cell_relative_reference', first_cell_relative_reference) if has_formula?
    end

    def set_range_reference_in_formula(range)
      options['formula'].sub!('range_absolute_reference', range.absolute_reference) if has_formula? && range
    end

    def style_name
      options['dxfId']
    end

    private

    def has_style?
      style_name
    end

    def has_formula?
      options['formula']
    end

    def style_not_set?
      style_name.is_a?(Symbol)
    end

	end
end