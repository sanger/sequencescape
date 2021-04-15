# frozen_string_literal: true

require 'rails_helper'

describe 'Receptacles API', with: :api_v2 do
  context 'with multiple receptacles of different types' do
    before do
      create(:untagged_well)
      create(:sample_tube)
      create(:library_tube)
      create(:lane)

      api_get '/api/v2/receptacles'
    end

    it 'sends a list of receptacles' do
      expect(response).to have_http_status(:success)
      # check to make sure the right amount of messages are returned
      expect(json['data'].length).to eq(4)
    end

    it 'identifies the type of receptacle' do
      listed = json['data'].map { |data| data['type'] }.sort
      expect(listed).to eq(%w(lanes receptacles receptacles wells))
    end

    # TODO: Check filters, ESPECIALLY if they aren't simple attribute filters
  end

  context 'with one receptacle' do
    let(:pcr_cycles) { 10 }
    let(:submit_for_sequencing) { true }
    let(:sub_pool) { 5 }
    let(:coverage) { 100 }
    let(:diluent_volume) { 50.0 }

    let(:receptacle) do
      create :receptacle,
             pcr_cycles: pcr_cycles,
             submit_for_sequencing: submit_for_sequencing,
             sub_pool: sub_pool,
             coverage: coverage,
             diluent_volume: diluent_volume
    end

    before do
      api_get "/api/v2/receptacles/#{receptacle.id}"
    end

    describe '#get' do
      it 'sends an individual receptacle' do
        expect(response).to have_http_status(:success)
        expect(json.dig('data', 'type')).to eq('receptacles')
      end

      it 'returns the receptacle with the correct attributes' do
        expect(json.dig('data', 'attributes', 'pcr_cycles')).to eq pcr_cycles
        expect(json.dig('data', 'attributes', 'submit_for_sequencing')).to eq submit_for_sequencing
        expect(json.dig('data', 'attributes', 'sub_pool')).to eq sub_pool
        expect(json.dig('data', 'attributes', 'coverage')).to eq coverage
        expect(json.dig('data', 'attributes', 'diluent_volume')).to eq diluent_volume.to_s
      end
    end

    describe '#update' do
      let(:updated_pcr_cycles) { 11 }
      let(:updated_submit_for_sequencing) { false }
      let(:payload) do
        {
          data: {
            id: receptacle.id,
            type: 'receptacles',
            attributes: {
              pcr_cycles: 11,
              submit_for_sequencing: false
            }
          }
        }
      end

      before do
        api_patch "/api/v2/receptacles/#{receptacle.id}", payload
      end

      it 'returns successful response with the updated attributes' do
        expect(response).to have_http_status(:success)
        expect(json.dig('data', 'attributes', 'pcr_cycles')).to eq(updated_pcr_cycles)
        expect(json.dig('data', 'attributes', 'submit_for_sequencing')).to eq(updated_submit_for_sequencing)
      end

      it 'updates a Receptacle' do
        updated_model = Receptacle.find(receptacle.id)
        expect(updated_model.pcr_cycles).to eq updated_pcr_cycles
        expect(updated_model.submit_for_sequencing).to eq updated_submit_for_sequencing
      end
    end
  end
end
