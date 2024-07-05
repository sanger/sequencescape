# frozen_string_literal: true

require 'rails_helper'

class NovaSeq6000ValidatorStub < CustomValidatorBase
  def validate(record)
    record.errors.add :base, 'NovaSeq6000Validator failed'
  end
end

# rubocop:disable Lint/ConstantDefinitionInBlock
RSpec.describe 'DynamicValidations' do
    context 'when added, includes the dynamic validations' do

      before do
        # Dynamically assign the stub class to the constant for the test environment
        stub_const('NovaSeq6000Validator', NovaSeq6000ValidatorStub)

      end

      let(:pipeline) { create :pipeline, validator_class_name: 'NovaSeq6000Validator'}
      let(:batch) { Batch.new(pipeline: pipeline) }


      it 'adds dynamic validations' do
        expect(batch.valid?).to be false
        expect(batch.errors[:base]).to include('NovaSeq6000Validator failed')
      end
    end
end
# rubocop:enable Lint/ConstantDefinitionInBlock