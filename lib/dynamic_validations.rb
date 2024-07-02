# frozen_string_literal: true

# This had to be loaded to call constantize
require_relative '../app/validators/nova_seq6000_validator'
require_relative '../app/validators/default_validator'

module DynamicValidations

  extend ActiveSupport::Concern

  included do
    after_initialize do
      add_dynamic_validations(self)
    end
  end

  # Adding dynamic validations to the model
  def add_dynamic_validations(batch)
    validator_class = get_validator_class(batch.pipeline)
    self.class.validates_with validator_class if validator_class
  end

  private

  def get_validator_class(pipeline)
    validator_class_name = pipeline&.validator_class_name
    validator_class_name.try(:constantize)
  end

end