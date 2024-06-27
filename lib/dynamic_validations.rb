# frozen_string_literal: true

module DynamicValidations
  def self.included(base)
    base.class_eval do
      after_initialize :add_dynamic_validations
    end
  end

  private

  def add_dynamic_validations
    # Define the class names that need to be validated
    # These needs to be fetched from pipeline record's 'validator' attribute
    class_names = []
    class_names.each do |class_name|
      # Get the class from the class name
      klass = class_name.constantize

      # Defining validation methods for each class
      self.class.send(:define_method, "validate_#{class_name.underscore}") do
        # Implement a method "valid?" on the class. This method should return true if the object is valid,
        # false otherwise. This method should be implemented by subclasses of CustomValidatorBase.
        errors.add(:base, "#{class_name} is invalid") unless klass.valid?
      end

      # Including validations in the class
      validate :"validate_#{class_name.underscore}"
    end
  end
end