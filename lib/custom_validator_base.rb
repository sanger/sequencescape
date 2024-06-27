# frozen_string_literal: true

# Base class for custom validators
# Subclasses should implement the validate method
# The validate method should return true if the object is valid, false otherwise
# Do we need to make subclass ActiveModel::Validator?
class CustomValidatorBase

  # This method should be implemented by subclasses to return true if the object is valid, false otherwise
  def validate
    raise NotImplementedError, 'Subclasses must implement a valid? method'
  end

end
