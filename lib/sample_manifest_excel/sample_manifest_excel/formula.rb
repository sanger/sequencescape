module SampleManifestExcel
  class Formula

    attr_accessor :type, :first_cell, :absolute_reference, :operator, :operand

    def initialize(attributes = {})
      add_attributes(attributes)
    end

    def update(attributes = {})
      add_attributes(attributes)
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

  private

    def add_attributes(attributes)
      attributes.each do |name, value|
        send("#{name}=", value)
      end
    end
  end
end