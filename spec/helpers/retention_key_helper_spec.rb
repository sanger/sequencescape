# frozen_string_literal: true

require 'spec_helper'
require 'rails_helper'

describe RetentionKeyHelper do
  describe '#find_retention_instruction_key_for_value' do
    subject { helper.find_retention_instruction_key_for_value(value) }

    context 'with a valid retention instruction' do
      let(:value) { 'Destroy after 2 years' }

      it { is_expected.to eq(:destroy_after_2_years) }
    end

    context 'with an invalid retention instruction' do
      let(:value) { 'invalid' }

      it { is_expected.to be_nil }
    end
  end

  describe '#find_retention_instruction_from_key' do
    subject { helper.find_retention_instruction_from_key(key) }

    context 'with a valid key' do
      let(:key) { :destroy_after_2_years }

      it { is_expected.to eq('Destroy after 2 years') }
    end

    context 'with an invalid key' do
      let(:key) { :invalid }

      it { is_expected.to be_nil }
    end
  end

  describe '#retention_instruction_option_for_select' do
    subject { helper.retention_instruction_option_for_select }

    it 'returns the retention instruction options for select' do
      expect(subject).to eq(
        [
          ['Destroy after 2 years', 'destroy_after_2_years'],
          ['Return to customer after 2 years', 'return_to_customer_after_2_years'],
          ['Long term storage', 'long_term_storage']
        ]
      )
    end
  end
end
