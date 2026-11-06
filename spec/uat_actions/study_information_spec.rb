# frozen_string_literal: true

require 'rails_helper'

describe UatActions::StudyInformation do
  context 'when the study exists' do
    let(:study) { create(:study, name: 'UAT Study') }
    let(:parameters) { { study_name: study.name } }
    let(:uat_action) { described_class.new(parameters) }
    let(:report) do
      # A report is a hash of key value pairs which get returned to the user.
      # It should include information such as barcodes and identifiers
      { study_name: study.name, study_uuid: study.uuid }
    end

    it 'can be performed' do
      expect(uat_action.perform).to be true
    end

    it 'generates the expected report' do
      uat_action.perform
      expect(uat_action.report).to eq report
    end
  end

  context 'when the study name does not match a study' do
    let(:parameters) { { study_name: 'INVALID' } }
    let(:uat_action) { described_class.new(parameters) }
    let(:report) do
      # A report is a hash of key value pairs which get returned to the user.
      # It should include information such as barcodes and identifiers
      { study_name: 'INVALID' }
    end

    it 'cannot be performed' do
      expect(uat_action.perform).to be false
    end

    it 'generates the expected report' do
      uat_action.perform
      expect(uat_action.report).to eq report
    end
  end

  it 'returns a default' do
    expect(described_class.default).to be_a described_class
  end
end
