# This module allows to set default attributes (static or dynamic)
# The main method is 'set_defaults', it takes a hash as an argument
# Keys in this hash are attributes names
# Value is either a default static value
# or a proc that takes the instance as an argument and evaluates to default value when called
# Example of usage:
# set_defaults attr_1: static_value, attr_2: ->(instance) { instance.any_required_method }
# !!! It probably will not work to set default booleans, update the code if you need this

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
        # With rails 4 association methods can take an optional boolean argument
        # When true, this forces the association to get reloaded.
        # This behaviour is deprecated in Rails 5, and removed in Rails 5.1
        super() || send("#{attribute}=", default_value || yield(self))
      end
    end
  end
end
