module SampleManifestExcel

  #ConditionalFormattingRule has all information about particular conditional formatting rule.
  #Constructor requires a hash of options, as in axlsx.
  #But as volues of some options are dynimic, they can not be hardcoded, so options in yaml file
  #look like this   {type: :expression, formula: "ISERROR(MATCH(first_cell_relative_reference,range_absolute_reference,0)>0)",
  # dxfId: :wrong_value, priority: 2}
  #dxfId should be later updated with a style reference, formula should be later updated with
  #actual first_cell_relative_reference and range_absolute_reference.
  #After applying #prepare, options should look like this:
  # {type: :expression, formula: "ISERROR(MATCH(G10,Ranges!$A$1:$D$1,0)>0)", dxfId: 1, priority: 2}
  #TO BE REFACTORED

	class ConditionalFormattingRule

    attr_reader :options

		def initialize(options)
			@options = options
		end

    #Prepares conditional formatting to be used with axlsx worksheet

    def prepare(style, first_cell_relative_reference, range)
      set_style(style)
      set_first_cell_in_formula(first_cell_relative_reference)
      set_range_reference_in_formula(range)
    end

    #Sets style option

    def set_style(style)
      options['dxfId'] = style.reference if has_style? && style_not_set?
    end

    #Updates formula with actual first cell reference

    def set_first_cell_in_formula(first_cell_relative_reference)
      options['formula'].sub!('first_cell_relative_reference', first_cell_relative_reference) if has_formula?
    end

    #Updates formula with actual reference to a range

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