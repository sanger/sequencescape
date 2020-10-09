# frozen_string_literal: true

#
# Module NestedValidation provides an ActiveModel compatible
# version of validates associated. Unlike the active model
# version however it actually propagates the error outwards.
#
# Usage:
#
# class MyHappyClass
#   extend NestedValidation
#
#   validates_nested :my_other_active_model_object
#
# end
#
module NestedValidation
  #
  # Validates associated records and propagates the errors back onto the parent
  # object
  #
  class NestedValidator < ActiveModel::EachValidator
    def validate_each(record, attribute, value)
      Array(value).each do |nested|
        next if nested.valid?

        nested.errors.each do |nested_attribute, nested_error|
          if nested_attribute == :base
            record.errors.add(attribute, nested_error)
          else
            record.errors.add("#{attribute}.#{nested_attribute}", nested_error)
          end
        end
      end
    end
  end

  #
  # Records of this class will call valid? on any associations provided
  # as attr_names. Errors on these records will be propagated out
  # @param *attr_names [Symbol] One or more associations to validate
  #
  # @return [NestedValidator]
  def validates_nested(*attr_names)
    validates_with NestedValidator, _merge_attributes(attr_names)
  end
end
