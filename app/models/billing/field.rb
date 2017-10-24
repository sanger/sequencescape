module Billing
  # represents a field in a row in BIF file
  class Field
    include ActiveModel::Model
    attr_accessor :name, :number_of_spaces, :position_from, :position_to, :constant_value, :right_justified, :order, :dynamic_attribute

    validates :name, :number_of_spaces, :position_from, :position_to, :order, presence: true

    def length
      position_to - position_from + 1
    end

    def alignment
      right_justified ? :rjust : :ljust
    end

    def value(billing_item = nil)
      constant_value || billing_item.send(dynamic_attribute)
    end
  end
end
