# frozen_string_literal: true

require 'rails_helper'

class PipelineXValidator < CustomValidatorBase
  def validate(record)
    record.errors.add :base, 'PipelineXValidator failed'
  end
end

class PipelineX
  include ActiveModel::Model
  include ActiveModel::Validations
  include DynamicValidations

  attr_accessor :validator_class_name

  def initialize(validator_class_name)
    @validator_class_name = validator_class_name
    add_dynamic_validations
  end

end

RSpec.describe DynamicValidations do
  it 'adds dynamic validations' do
    pipeline = PipelineX.new( 'PipelineXValidator')
    pipeline.valid?
    expect(pipeline.errors[:base]).to include('PipelineXValidator failed')
  end
end