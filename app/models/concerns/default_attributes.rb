# This module allows to set default attributes (static or dynamic)
# The main method is 'set_defaults', it takes a hash as an argument
# Keys in this hash are attributes names
# Value is either a default static value
# or a proc that takes the instance as an argument and evaluates to default value when called
# Example of usage:
# set_defaults attr_1: static_value, attr_2: ->(instance) { instance.any_required_method }

module DefaultAttributes
  extend ActiveSupport::Concern

  module ClassMethods
    def set_defaults(attributes = {})
      attributes.each do |attribute, default_value|
        if default_value.is_a? Proc
          set_default(attribute, &default_value)
        else
          set_default(attribute, default_value)
        end
      end
    end

    def set_default(attribute, default_value = nil, &default_value_block)
      define_method(attribute) do
        super || default_value || yield(self)
      end
    end
  end
end
