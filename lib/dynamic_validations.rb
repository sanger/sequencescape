# frozen_string_literal: true

module DynamicValidations

  def add_dynamic_validations
    validator_class_name = 'PipelineXValidator'
    self.class.validates_with validator_class_name.constantize
  end

end