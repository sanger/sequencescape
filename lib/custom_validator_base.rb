# frozen_string_literal: true

# Base class for custom validators
# Subclasses should implement the validate method
# The validate method should return true if the object is valid, false otherwise
class CustomValidatorBase < ActiveModel::Validator

  # This method should be implemented by subclasses to return true if the object is valid, false otherwise
  def validate
    raise NotImplementedError, 'Subclasses must implement a valid? method'
  end

end
