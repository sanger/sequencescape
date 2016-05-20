module SampleManifestExcel
  class Formula

    include Comparable

    # TYPES = {
    #   is_text: "ISTEXT(#{first_cell})",
    #   is_number: "ISNUMBER(#{first_cell})",
    #   len: "LEN(#{first_cell})#{operator}#{operand}",
    #   is_error: "ISERROR(MATCH(#{first_cell},#{absolute_reference},0)>0)"
    # }

    attr_accessor :type, :first_cell, :absolute_reference, :operator, :operand

    def initialize(attributes = {})
      add_attributes(attributes)
    end

    def update(attributes = {})
      add_attributes(attributes)
      self
    end

    def to_s
      # TYPES[type]
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

    def <=>(other)
      type <=> other.type && 
      operator <=> other.operator &&
      operand <=> other.operand &&
      first_cell <=> other.first_cell &&
      absolute_reference <=> other.absolute_reference
    end

  private

    def add_attributes(attributes)
     attributes.each do |name, value|
        send("#{name}=", value)
      end
    end

    def default_attributes
      {
        type: :len,
        operator: ">",
        operand: 999
      }
    end
  end
end