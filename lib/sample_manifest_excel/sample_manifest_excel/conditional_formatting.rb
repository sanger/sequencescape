module SampleManifestExcel
  ##
  # A single conditional formatting rule.
  # This will consist of:
  # - options: which relate to Excel options e.g. type: :cellIs
  # - style: The style which will be added when conditional formatting applies.
  # - formula: See Formula class.
  class ConditionalFormatting
    include HashAttributes

    set_attributes :options, :style, :formula

    def initialize(attributes = {})
      create_attributes(attributes)
    end

    ##
    # If a worksheet attribute is present then add the conditional formatting
    # style to the workbook.
    # If conditional formatting has a formula then update the formula option
    # with the passed attributes.
    def update(attributes = {})
      if attributes[:worksheet].present?
        options['dxfId'] = attributes[:worksheet].workbook.styles.add_style(style)
      end

      if formula.present?
        options['formula'] = formula.update(attributes).to_s
      end

      self
    end

    ##
    # Create a new Formula object.
    def formula=(options)
      @formula = Formula.new(options)
    end

    ##
    # A conditional formatting is styled if the dxfId is present.
    def styled?
      options['dxfId'].present?
    end

    ##
    # A conditional formatting is only valid if there are some options.
    def valid?
      options.present?
    end

    ##
    # Return the options as a hash
    def to_h
      options.to_hash
    end

    def initialize_dup(source)
      self.options = source.options.dup
      if source.formula.present?
        self.formula = source.formula.to_h
      end
      super
    end
  end
end
