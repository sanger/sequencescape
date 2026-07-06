# frozen_string_literal: true

module SequencescapeExcel
  ##
  # A single conditional formatting rule.
  # This will consist of:
  # - options: which relate to Excel options e.g. type: :cellIs
  # - style: The style which will be added when conditional formatting applies.
  # - formula: See Formula class.
  class ConditionalFormatting
    include Helpers::Attributes

    setup_attributes :name, :options, :style, :formula

    validates_presence_of :name, :options

    def initialize(attributes = {})
      super
    end

    ##
    # If a worksheet attribute is present then add the conditional formatting
    # style to the workbook.
    # If conditional formatting has a formula then update the formula option
    # with the passed attributes.
    def update(attributes = {})
      options['dxfId'] = attributes[:worksheet].workbook.styles.add_style(style) if attributes[:worksheet].present?
      options['formula'] = formula.update(attributes).to_s if formula.present?
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
    # def valid?
    #   options.present?
    # end

    ##
    # Return the options as a hash
    def to_h
      options.to_hash
    end

    def initialize_dup(source)
      self.options = source.options.dup
      self.formula = source.formula.to_h if source.formula.present?
      super
    end

    def inspect
      "<#{self.class}: @name=#{name}, @options=#{options}, @style=#{style}, @formula=#{formula}>"
    end
  end
end
