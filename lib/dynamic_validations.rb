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

      # Including validations in the class
      validates_with class_name.constantize
    end
  end
end