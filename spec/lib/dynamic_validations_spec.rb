# frozen_string_literal: true

require 'spec_helper'

module DynamicValidationsTest

  extend ActiveSupport::Concern

  # Add the following in the real logic which is not supported in the test.
  # For it to be supported PipelineX should be an ActiveRecord model.
  #
  # included do
  #   after_initialize do |record|
  #     add_dynamic_validations(record)
  #   end
  # end

  def add_dynamic_validations(record)
    self.class.validates_with record.validator_class_name.constantize
  end

end

# In the business logic, if a pipeline X wants custom validations, it should:
# 0. Add a migration to add attribute validator_class_name to pipelines table
# 1. Implement the custom validator class
# 2. Include the DynamicValidations module
# 3. Call add_dynamic_validations in the initialize method.
class PipelineXValidator < CustomValidatorBase
  def validate(record)
    record.errors.add :base, 'PipelineXValidator failed'
  end
end

class PipelineX
  include ActiveModel::Model
  include ActiveModel::Validations
  include DynamicValidationsTest

  attr_accessor :validator_class_name

  # In real logic, this would be a dynamic list of validations
  # It should be possible to access validator_class_name from the record (because it's in pipelines schema)
  # We wouldn't need to override initialize, because it's called in the after_initialize hook. Overriding this
  # is for test purposes only.
  def initialize(validator_class_name)
    # This is not required in the real logic, because it's part of the schema
    @validator_class_name = validator_class_name
    # This is not required in the real logic, because it's called in the after_initialize hook
    add_dynamic_validations(self)
  end

end

RSpec.describe DynamicValidations do
  it 'adds dynamic validations' do
    pipeline = PipelineX.new( 'PipelineXValidator')
    pipeline.valid?
    expect(pipeline.errors[:base]).to include('PipelineXValidator failed')
  end
end