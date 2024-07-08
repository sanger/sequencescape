# frozen_string_literal: true

require 'rails_helper'

# rubocop:disable Lint/ConstantDefinitionInBlock
RSpec.describe 'DynamicValidations' do
    context 'when added, includes the dynamic validations' do

      before do
        # Define an anonymous class with the desired behavior
        nova_seq6000_validator = Class.new(CustomValidatorBase) do
          def validate(record)
            record.errors.add :base, 'NovaSeq6000Validator failed'
          end
        end

        # Assign the anonymous class to a constant for this test
        stub_const('NovaSeq6000Validator', nova_seq6000_validator)
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