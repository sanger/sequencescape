# frozen_string_literal: true

require 'rails_helper'

describe UatActions::GenerateSampleManifest do
  context 'with valid options' do

    let(:study) { create(:study, name: 'Test Study') }
    let(:supplier) { create(:supplier, name: 'Test Supplier') }
    let(:uat_action) { described_class.new(parameters) }

    context 'when generating a sample manfiest for a list of barcodes' do
      let(:parameters) do
        { study: study, supplier: supplier, asset_type: 'tube', count: 2 }
      end

      it 'can be performed' do
        expect(uat_action.perform).to eq true
      end
    end
  end

  it 'returns a default' do
    expect(described_class.default).to be_a described_class
  end
end
