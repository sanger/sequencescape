# frozen_string_literal: true

require 'rails_helper'

describe SupportActions::DummySupportAction do
  context 'with valid options' do
    let(:persisted) { SupportAction.new }
    let(:parameters) { { action: persisted } }
    let(:support_action) { described_class.new(parameters) }

    it 'can be performed' do
      expect(support_action.perform).to be true
      expect(support_action.log).to eq('Testing')
    end
  end

  it 'returns a default' do
    expect(described_class.default).to be_a described_class
  end
end
