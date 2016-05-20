module SampleManifestExcel

	class ConditionalFormatting

    attr_accessor :options, :style, :formula

		def initialize(attributes={})
      attributes.each do |name, value|
        send("#{name}=", value)
      end
		end

    def update(attributes = {})
      if attributes[:workbook].present?
        options['dxfId'] = attributes[:workbook].styles.add_style(style)
      else
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