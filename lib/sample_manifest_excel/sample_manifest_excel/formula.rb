module SampleManifestExcel
  class Formula

    include HashAttributes

    set_attributes :type, :first_cell, :absolute_reference, :operator, :operand, defaults: { type: :len, operator: ">", operand: 999}

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
        "ISTEXT(#{first_cell})"
      when :is_number
        "ISNUMBER(#{first_cell})"
      when :len
        "LEN(#{first_cell})#{operator}#{operand}"
      when :is_error
        "ISERROR(MATCH(#{first_cell},#{absolute_reference},0)>0)"
      end
    end

  end
end