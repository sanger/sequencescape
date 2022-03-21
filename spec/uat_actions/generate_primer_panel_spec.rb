# frozen_string_literal: true

require 'rails_helper'

describe UatActions::GeneratePrimerPanel do
  context 'with valid options' do
    let(:parameters) do
      {
        name: 'Test primer panel',
        snp_count: '24',
        pcr_1_name: 'Prog 1',
        pcr_2_name: 'Prog 2',
        pcr_1_duration: 40,
        pcr_2_duration: 40
      }
    end
    let(:uat_action) { described_class.new(parameters) }
    let(:report) do
      # A report is a hash of key value pairs which get returned to the user.
      # It should include information such as barcodes and identifiers
      { name: 'Test primer panel' }
    end

    it 'can be performed' do
      expect(uat_action.perform).to be true
      expect(uat_action.report).to eq report
      expect(PrimerPanel.find_by(name: 'Test primer panel').snp_count).to eq 24
    end
  end

  it 'returns a default' do
    expect(described_class.default).to be_a described_class
  end
end
