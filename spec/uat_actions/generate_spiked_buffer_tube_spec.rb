# frozen_string_literal: true

require 'rails_helper'

describe UatActions::GenerateSpikedBufferTube do
  context 'with valid options' do
    before { create(:study, name: PhiX.configuration[:default_study_option]) }

    let(:uat_action) { described_class.new(parameters) }

    context 'when creating a single spiked buffer tube' do
      let(:parameters) { { tube_count: 1 } }

      it 'can be performed' do
        expect { uat_action.perform }.to change(Tube, :count).by(2) # One parent stock and one child SpikedBuffer
        expect(uat_action.perform).to be true
        expect(uat_action.report['tube_0']).to eq SpikedBuffer.last.human_barcode
        expect(SpikedBuffer.last.receptacles.first.aliquots.first.sample).to eq PhiX.sample
      end
    end

    context 'when creating multiple tubes' do
      let(:parameters) { { tube_count: 4 } }

      it 'can be performed' do
        expect { uat_action.perform }.to change(Tube, :count).by(5) # One parent stock and four child SpikedBuffers
        expect(uat_action.perform).to be true
        expect(uat_action.report.size).to eq 4
      end
    end
  end

  it 'returns a default' do
    expect(described_class.default).to be_a described_class
  end
end
