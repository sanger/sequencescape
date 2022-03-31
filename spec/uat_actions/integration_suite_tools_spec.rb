# frozen_string_literal: true

require 'rails_helper'

describe UatActions::IntegrationSuiteTools do
  context 'valid options' do
    let(:parameters) { {} }
    let(:uat_action) { described_class.new(parameters) }
    let(:report) { { user_swipecard: '__uat_test__', user_login: '__uat_test__' } }

    it 'can be performed' do
      expect(uat_action.perform).to be true
      expect(uat_action.report).to eq report
    end
  end

  it 'returns a default' do
    expect(described_class.default).to be_a described_class
  end
end
