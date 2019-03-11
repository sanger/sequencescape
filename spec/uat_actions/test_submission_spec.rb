# frozen_string_literal: true

require 'rails_helper'

describe UatActions::TestSubmission do
  context 'valid options' do
    let(:parameters) { {} }
    let(:uat_action) { described_class.new(parameters) }
    let(:report) do
      # A report is a hash of key value pairs which get returned to the user.
      # It should include information such as barcodes and identifiers
      {}
    end

    it 'can be performed' do
      expect(uat_action.perform).to eq true
      expect(uat_action.report).to eq report
    end
  end

  it 'returns a default' do
    expect(described_class.default).to be_a described_class
  end
end
