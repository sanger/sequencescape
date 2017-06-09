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
