# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'DynamicValidations' do
    context 'when added, includes the dynamic validations' do
      let(:pipeline) { create :pipeline, validator_class_name: 'NovaSeq6000Validator'}
      let(:batch) { Batch.new(pipeline: pipeline) }

      it 'adds dynamic validations' do
        expect(batch.valid?).to be false
        expect(batch.errors[:base]).to include('NovaSeq6000Validator failed')
      end
    end
end