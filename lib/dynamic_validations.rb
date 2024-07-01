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

  def add_dynamic_validations(batch)
    pipeline = batch.pipeline
    return if pipeline.blank?
    validator_class_name = pipeline.validator_class_name
    validator_class = validator_class_name.constantize if validator_class_name.present?
    self.class.validates_with validator_class if validator_class < ActiveModel::Validator
  end

end