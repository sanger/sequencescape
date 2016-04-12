module SampleManifestExcel

  class Column

    include ActiveModel::Validations

    attr_accessor :name, :heading, :position, :type, :attribute, :validation, :value, :protection, :unlock_num
    attr_reader :first_cell, :last_cell, :range

    validates_presence_of :name, :heading

    def initialize(attributes = {})
      attributes.each do |name, value|
        send("#{name}=", value)
      end
    end

    def position
      @position ||= 0
    end

    # turn position into characters for excel
    # examples:
    # - if position is 0 return nil
    # - if position is less than 26 return single character e.g. 1 = "A", 26 = "Z"
    # - if position is greater than 26 return two characters e.g. 27 = "AA"
    def position_alpha
      return if position == 0
      (position-1)<26 ? ((position-1)%26+65).chr : ((position-1)/26+64).chr + ((position-1)%26+65).chr
    end

    def type
      @type ||= :string
    end

    def attribute?
      attribute.present?
    end

    def validation?
      validation.present?
    end

    def protection?
      protection
    end

    def value
      @value ||= ""
    end

    def actual_value(object)
      attribute? ? attribute_value(object) : value
    end

    def attribute_value(object)
      attribute.values.first.call(object)
    end

    def set_position(position)
      self.position = position
      self
    end

    def set_validation(validation)
      self.validation = validation
      self
    end

    def unlock(num)
      self.unlock_num = num
      self
    end

    def add_range(first_row, last_row)
      @first_cell = "#{position_alpha}#{first_row}"
      @last_cell = "#{position_alpha}#{last_row}"
      @range = "#{first_cell}:#{last_cell}"
    end
   
  end

end