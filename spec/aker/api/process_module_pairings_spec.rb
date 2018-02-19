require 'rails_helper'

RSpec.describe Api::V2::Aker::ProcessModulePairingsController, type: :request, aker: true do
  describe 'index' do
    let!(:process_module_pairings) { create_list(:aker_process_module_pairing, 3) }

    before(:each) do
      get api_v2_aker_process_module_pairings_path
    end

    it 'is a success' do
      expect(response).to be_success
    end

    it 'returns the correct number of process module pairings' do
      json = ActiveSupport::JSON.decode(response.body)
      expect(json['data'].length).to eq(3)
    end
  end

  describe 'show' do
    let(:aker_process_module_pairing) { create(:aker_process_module_pairing) }

    before(:each) do
      get api_v2_aker_process_module_pairing_path(aker_process_module_pairing.id)
    end

    it 'is a success' do
      expect(response).to be_success
    end

    it 'returns the correct attributes' do
      json = ActiveSupport::JSON.decode(response.body)['data']['attributes']
      expect(json['default_path']).to eq(aker_process_module_pairing.default_path)
      expect(json['from_step']).to eq(aker_process_module_pairing.from_step.name)
      expect(json['to_step']).to eq(aker_process_module_pairing.to_step.name)
    end
  end
end
