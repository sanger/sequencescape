# frozen_string_literal: true

require 'rails_helper'

describe 'Wells API', with: :api_v2 do
  context 'with multiple wells' do
    before do
      create_list(:well, 5)
      api_get '/api/v2/wells'
    end

    it 'sends a list of wells' do
      expect(response).to have_http_status(:success)

      # check to make sure the right amount of messages are returned
      expect(json['data'].length).to eq(5)
    end

    # TO DO: Check filters, ESPECIALLY if they aren't simple attribute filters
  end

  context 'with one well' do
    let(:pcr_cycles) { 10 }
    let(:submit_for_sequencing) { true }
    let(:sub_pool) { 5 }
    let(:coverage) { 100 }
    let(:diluent_volume) { 50.0 }
    let(:hyb_panel) { 'Hyb Panel 1' }

    let(:well) do
      create :well,
             pcr_cycles: pcr_cycles,
             submit_for_sequencing: submit_for_sequencing,
             sub_pool: sub_pool,
             coverage: coverage,
             diluent_volume: diluent_volume,
             hyb_panel: hyb_panel
    end

    describe '#get' do
      before { api_get "/api/v2/wells/#{well.id}" }

      it 'sends an individual well' do
        expect(response).to have_http_status(:success)
        expect(json.dig('data', 'type')).to eq('wells')
      end

      it 'returns correct attributes' do
        expect(json.dig('data', 'attributes', 'pcr_cycles')).to eq pcr_cycles
        expect(json.dig('data', 'attributes', 'submit_for_sequencing')).to eq submit_for_sequencing
        expect(json.dig('data', 'attributes', 'sub_pool')).to eq sub_pool
        expect(json.dig('data', 'attributes', 'coverage')).to eq coverage
        expect(json.dig('data', 'attributes', 'diluent_volume')).to eq diluent_volume.to_s
        expect(json.dig('data', 'attributes', 'hyb_panel')).to eq hyb_panel
      end
    end

    describe '#update' do
      let(:payload) do
        {
          data: {
            id: well.id,
            type: 'wells',
            attributes: {
              pcr_cycles: 11,
              submit_for_sequencing: false,
              sub_pool: 2,
              coverage: 50,
              diluent_volume: 34.0,
              hyb_panel: 'Hyb Panel 1'
            }
          }
        }
      end

      before { api_patch "/api/v2/wells/#{well.id}", payload }

      it 'returns successful response' do
        expect(response).to have_http_status(:success)
      end

      it 'returns correct updated attributes' do
        expect(json.dig('data', 'attributes', 'pcr_cycles')).to eq(11)
        expect(json.dig('data', 'attributes', 'submit_for_sequencing')).to be(false)
        expect(json.dig('data', 'attributes', 'sub_pool')).to eq(2)
        expect(json.dig('data', 'attributes', 'coverage')).to eq(50)
        expect(json.dig('data', 'attributes', 'diluent_volume')).to eq('34.0')
        expect(json.dig('data', 'attributes', 'hyb_panel')).to eq('Hyb Panel 1')
      end

      it 'updates the well' do
        updated_model = Well.find(well.id)
        expect(updated_model.pcr_cycles).to eq 11
        expect(updated_model.submit_for_sequencing).to be false
        expect(updated_model.sub_pool).to eq 2
        expect(updated_model.coverage).to eq 50
        expect(updated_model.diluent_volume).to eq 34.0
        expect(updated_model.hyb_panel).to eq 'Hyb Panel 1'
      end
    end
  end
end
