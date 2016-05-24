module SampleManifestExcel

	class ConditionalFormatting

    include HashAttributes

    set_attributes :options, :style, :formula

		def initialize(attributes={})
      create_attributes(attributes)
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

    def to_h
      options
    end

	end
end