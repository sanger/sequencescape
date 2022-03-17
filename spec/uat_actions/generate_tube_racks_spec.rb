# frozen_string_literal: true

require 'rails_helper'

describe UatActions::GenerateTubeRacks do
  context 'with valid options' do
    let(:study) { create(:study, name: 'Test Study') }
    let(:parameters) { { rack_count: 1, study_name: study.name } }
    let(:uat_action) { described_class.new(parameters) }

    context 'when creating a single tube rack' do
      it 'can be performed' do
        expect(uat_action.perform).to be true
        expect(uat_action.report['rack_0']).to be_present
        expect(
          TubeRack.find_by_barcode(uat_action.report['rack_0']).tube_receptacles.first.aliquots.first.study
        ).to eq study
      end
    end

    context 'when creating multiple tube racks' do
      let(:parameters) { { rack_count: 3, study_name: study.name } }

      it 'can be performed' do
        expect(uat_action.perform).to be true
        expect(uat_action.report['rack_0']).to be_present
        expect(uat_action.report['rack_1']).to be_present
        expect(uat_action.report['rack_2']).to be_present
      end
    end
  end

  it 'returns a default' do
    expect(described_class.default).to be_a described_class
  end
end
