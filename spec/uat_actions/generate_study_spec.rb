# frozen_string_literal: true

require 'rails_helper'

describe UatActions::GenerateStudy do
  context 'with valid options' do
    let(:uat_action) { described_class.new(parameters) }
    let(:study_name) { 'Test Study' }
    let(:parameters) { { study_name: study_name } }

    describe '#perform' do
      context 'when generating a study' do
        it 'generates a study' do
          expect { uat_action.perform }.to(change { Study.all.count }.by(1))
        end

        it 'creates the study with the correct data' do
          uat_action.perform
          expect(Study.last.name).to eq study_name
        end
      end
    end
  end

  describe '#default' do
    it 'returns a default' do
      expect(described_class.default).to be_a described_class
    end
  end
end
