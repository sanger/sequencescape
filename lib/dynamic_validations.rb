# frozen_string_literal: true

module DynamicValidations

  extend ActiveSupport::Concern

  included do
    after_initialize do |record|
      add_dynamic_validations(record)
    end
  end

  def add_dynamic_validations(record)
    self.class.validates_with record.validator_class_name.constantize
  end

end