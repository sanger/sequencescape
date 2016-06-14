module SampleManifestExcel
  class Formula

    include HashAttributes

    OPERATORS = { gt: ">", lt: "<"}

    set_attributes :type, :first_cell_reference, :absolute_reference, :operator, :operand, defaults: { type: :len, operator: :gt, operand: 999}

    def initialize(attributes = {})
      create_attributes(attributes)
    end

    def update(attributes = {})
      update_attributes(attributes)
      self
    end

    def to_s
      case type
      when :is_text
        "ISTEXT(#{first_cell_reference})"
      when :is_number
        "ISNUMBER(#{first_cell_reference})"
      when :len
        "LEN(#{first_cell_reference})#{OPERATORS[operator]}#{operand}"
      when :is_error
        "ISERROR(MATCH(#{first_cell_reference},#{absolute_reference},0)>0)"
      end
    end

  end
end