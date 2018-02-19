require 'rails_helper'

RSpec.describe Api::V2::Aker::ProcessesController, type: :request, aker: true do
  describe 'index' do
    let!(:aker_processes) { create_list(:aker_process, 3) }

    before(:each) do
      get api_v2_aker_processes_path
    end

    it 'is a success' do
      expect(response).to be_success
    end

    it 'returns the correct number of processes' do
      json = ActiveSupport::JSON.decode(response.body)
      expect(json['data'].length).to eq(3)
    end
  end

  describe 'show' do
    let(:aker_process) { create(:aker_process_with_process_module_pairings) }

    before(:each) do
      get api_v2_aker_process_path(aker_process.id)
    end

    it 'is a success' do
      expect(response).to be_success
    end

    it 'returns the correct attributes' do
      json = ActiveSupport::JSON.decode(response.body)['data']
      expect(json['attributes']['name']).to eq(aker_process.name)
      expect(json['attributes']['tat']).to eq(aker_process.tat)
      expect(json['relationships']['process_module_pairings']['data'].length).to eq(3)
    end
  end
end
