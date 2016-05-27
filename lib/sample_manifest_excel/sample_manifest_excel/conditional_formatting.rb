module SampleManifestExcel

	class ConditionalFormatting

    include HashAttributes

    FORMULAS = [:len, :is_number, :is_text, :is_error]

    set_attributes :options, :style, :formula, :type

		def initialize(attributes={})
      create_attributes(attributes)
      binding.pry
      if FORMULAS.include? type
        formula = attributes
      end
		end

    def update(attributes = {})

      if attributes[:workbook].present?
        options['dxfId'] = attributes[:workbook].styles.add_style(style)
      end

      if formula.present?
        options['formula'] = formula.update(attributes).to_s
      end

      self
    end

    def formula=(options)
      @formula = Formula.new(options)
    end

    def styled?
      options['dxfId'].present?
    end

    def valid?
      options.present?
    end

    def to_h
      options
    end

	end
end