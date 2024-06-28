# frozen_string_literal: true

module DynamicValidations

  def add_dynamic_validations(record)
    self.class.validates_with record.validator_class_name.constantize
  end

end