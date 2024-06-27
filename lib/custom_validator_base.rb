# frozen_string_literal: true

class CustomValidatorBase

  # This method should be implemented by subclasses to return true if the object is valid, false otherwise
  def valid?
    raise NotImplementedError, 'Subclasses must implement a valid? method'
  end

end
