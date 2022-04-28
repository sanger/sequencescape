# frozen_string_literal: true
module Attributable
  # A custom validator allows options to be imported from the database.
  class CustomValidator < ActiveModel::EachValidator
    def validate_each(record, attribute, value)
      valid = record.validator_for(attribute).validate?(value)
      record.errors.add(attribute, 'is not a valid option') unless valid
      valid
    end
  end
end
