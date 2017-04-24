module Attributable
  class CustomValidator < ActiveModel::EachValidator
    def validate_each(record, attribute, value)
      valid = record.validator_for(attribute).valid_options.include?(value)
      record.errors.add(attribute, 'is not a valid option') unless valid
      valid
    end
  end
end
