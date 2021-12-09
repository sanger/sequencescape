# frozen_string_literal: true

require 'rails_helper'

describe UatActions::GenerateTagGroup do
  context 'when valid options' do
    let(:parameters) { { name: 'Test group', size: '3' } }
    let(:uat_action) { described_class.new(parameters) }
    let(:report) do
      # A report is a hash of key value pairs which get returned to the user.
      # It should include information such as barcodes and identifiers
      { name: 'Test group' }
    end

    it 'can be performed' do
      expect(uat_action.perform).to eq true
      expect(uat_action.report).to eq report
      expect(TagGroup.find_by(name: 'Test group').tags.count).to eq 3
      expect(TagGroup.find_by(name: 'Test group').adapter_type_id).to be_nil
    end

    context 'with an adapter type' do
      let(:adapter_type) { create(:adapter_type) }
      let(:parameters) { { name: 'Test group', size: '3', adapter_type_name: adapter_type.name } }

      it 'can be performed' do
        expect(uat_action.perform).to eq true
        expect(uat_action.report).to eq report
        expect(TagGroup.find_by(name: 'Test group').tags.count).to eq 3
        expect(TagGroup.find_by(name: 'Test group').adapter_type_id).to eq adapter_type.id
      end
    end
  end

  it 'returns a default' do
    expect(described_class.default).to be_a described_class
  end
end
