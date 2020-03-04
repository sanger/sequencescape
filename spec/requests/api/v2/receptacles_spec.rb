# frozen_string_literal: true

require 'rails_helper'

describe 'Receptacles API', with: :api_v2 do
  context 'with multiple receptacles of different types' do
    before do
      create(:untagged_well)
      create(:sample_tube)
      create(:library_tube)
      create(:lane)
    end

    it 'sends a list of receptacles' do
      api_get '/api/v2/receptacles'
      # test for the 200 status-code
      expect(response).to have_http_status(:success)
      # check to make sure the right amount of messages are returned
      expect(json['data'].length).to eq(4)
    end

    it 'identifies the type of receptacle' do
      api_get '/api/v2/receptacles'
      listed = json['data'].map { |data| data['type'] }.sort
      expect(listed).to eq(%w(lanes receptacles receptacles wells))
    end
    # Check filters, ESPECIALLY if they aren't simple attribute filters
  end

  context 'with a request' do
    let(:resource_model) { create :receptacle }

    it 'sends an individual receptacle' do
      api_get "/api/v2/receptacles/#{resource_model.id}"
      expect(response).to have_http_status(:success)
      expect(json.dig('data', 'type')).to eq('receptacles')
    end
  end

  context 'with a receptacles' do
    let(:pcr_cycles) { 10 }
    let(:submit_for_sequencing) { true }
    let(:sub_pool) { 5 }
    let(:coverage) { 100 }

    let(:receptacle) { create :receptacle, pcr_cycles: pcr_cycles, submit_for_sequencing: submit_for_sequencing, sub_pool: sub_pool, coverage: coverage }

    describe '#get' do
      it 'returns the receptacle with the correct attributes' do
        api_get "/api/v2/receptacles/#{receptacle.id}"
        expect(json.dig('data', 'attributes', 'pcr_cycles')).to eq pcr_cycles
        expect(json.dig('data', 'attributes', 'submit_for_sequencing')).to eq submit_for_sequencing
        expect(json.dig('data', 'attributes', 'sub_pool')).to eq sub_pool
        expect(json.dig('data', 'attributes', 'coverage')).to eq coverage
      end
    end

    describe '#update' do
      let(:updated_pcr_cycles) { 11 }
      let(:updated_submit_for_sequencing) { false }
      let(:payload) do
        {
          'data': {
            'id': receptacle.id,
            'type': 'receptacles',
            'attributes': {
              'pcr_cycles': 11,
              'submit_for_sequencing': false
            }
          }
        }
      end

      it 'returns successful response with the updated attributes' do
        api_patch "/api/v2/receptacles/#{receptacle.id}", payload
        # json = ActiveSupport::JSON.decode(response.body)
        expect(json.dig('data', 'attributes', 'pcr_cycles')).to eq(updated_pcr_cycles)
        expect(json.dig('data', 'attributes', 'submit_for_sequencing')).to eq(updated_submit_for_sequencing)
        expect(response).to have_http_status(:success)
      end

      it 'updates a Receptacle' do
        api_patch "/api/v2/receptacles/#{receptacle.id}", payload
        updated_model = Receptacle.find(receptacle.id)
        expect(updated_model.pcr_cycles).to eq updated_pcr_cycles
        expect(updated_model.submit_for_sequencing).to eq updated_submit_for_sequencing
      end
    end
  end
end
