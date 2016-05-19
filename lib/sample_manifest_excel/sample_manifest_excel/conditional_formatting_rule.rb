module SampleManifestExcel

  #ConditionalFormattingRule has all information about particular conditional formatting rule.
  #Axlsx requires a hash of options to use conditional formatting.
  #Values of some options (like formula and dxfId (style)) are dynimic, they can not be hardcoded, so:
  #- if style update is required, conditional formatting has an attribute 'style' with style_name,
  #- if formula update is required, conditional formatting has an attribute 'formula' with raw formula that looks
  #like this "ISERROR(MATCH(first_cell_relative_reference,range_absolute_reference,0)>0)",
  #Also conditional formatting always has an attribute options, which is needed for axlsx. It look like this
  #{type: :expression, priority: 2}
  #Proper style is later assigned to 'dxfId' (as required by axlsx), formula is later updated with
  #actual first_cell_relative_reference and range_absolute_reference.
  #After applying #prepare, options should look something like this:
  # {type: :expression, formula: "ISERROR(MATCH(G10,Ranges!$A$1:$D$1,0)>0)", dxfId: 1, priority: 2}

	class ConditionalFormattingRule

    attr_accessor :options, :style, :formula

		def initialize(attributes={})
      attributes.each do |name, value|
        send("#{name}=", value)
      end
		end

    def formula=(options)
      @formula = Formula.new(options)
    end

    #Prepares conditional formatting to be used with axlsx worksheet

    def prepare(style, first_cell, absolute_reference)
      set_style(style)
      set_formula(first_cell, absolute_reference)
    end

    #Sets style in options

    def set_style(style)
      options['dxfId'] = style.reference if has_style? && style_not_set?
    end

    #Sets formula in options

    def set_formula(first_cell, absolute_reference)
      if formula.present?
        options['formula'] = formula.update(first_cell: first_cell, absolute_reference: absolute_reference).to_s 
      end
    end

    def valid?
      options.present?
    end

    private

    def has_style?
      style
    end

    def style_not_set?
      !options['dxfId']
    end

	end
end