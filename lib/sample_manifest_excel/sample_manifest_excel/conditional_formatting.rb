module SampleManifestExcel

	class ConditionalFormatting

    include HashAttributes

    set_attributes :options, :style, :formula, :type

		def initialize(attributes={})
      create_attributes(attributes)
		end

    def update(attributes = {})

      if attributes[:worksheet].present?
        options['dxfId'] = attributes[:worksheet].workbook.styles.add_style(style)
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
      options.to_hash
    end

	end
end