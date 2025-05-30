# frozen_string_literal: true

require 'rails_helper'
require './spec/requests/api/v2/shared_examples/api_key_authenticatable'
require './spec/requests/api/v2/shared_examples/requests'

describe 'Receptacles API', with: :api_v2 do
  let(:base_endpoint) { '/api/v2/receptacles' }

  it_behaves_like 'ApiKeyAuthenticatable'

  context 'with multiple receptacles of different types' do
    before do
      create(:untagged_well)
      create(:sample_tube)
      create(:library_tube)
      create(:lane)

      api_get base_endpoint
    end

    it 'sends a list of receptacles' do
      expect(response).to have_http_status(:success)

      # check to make sure the right amount of messages are returned
      expect(json['data'].length).to eq(4)
    end

    it 'identifies the type of receptacle' do
      listed = json['data'].pluck('type').sort
      expect(listed).to eq(%w[lanes receptacles receptacles wells])
    end

    # TODO: Check filters, ESPECIALLY if they aren't simple attribute filters
  end

  context 'with one receptacle' do
    let(:pcr_cycles) { 10 }
    let(:submit_for_sequencing) { true }
    let(:sub_pool) { 5 }
    let(:coverage) { 100 }
    let(:diluent_volume) { 50.0 }

    let(:receptacle) { create(:receptacle, pcr_cycles:, submit_for_sequencing:, sub_pool:, coverage:, diluent_volume:) }

    before { api_get "#{base_endpoint}/#{receptacle.id}" }

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

      before { api_patch "#{base_endpoint}/#{receptacle.id}", payload }

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
