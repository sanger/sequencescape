# frozen_string_literal: true

require 'rails_helper'
require './spec/requests/api/v2/shared_examples/api_key_authenticatable'

describe 'Labware API', with: :api_v2 do
  let(:base_endpoint) { '/api/v2/labware' }

  it_behaves_like 'ApiKeyAuthenticatable'

  context 'with multiple receptacles of different types' do
    before do
      create(:sample_tube)
      create(:library_tube)
    end

    it 'sends a list of labware' do
      api_get base_endpoint

      # test for the 200 status-code
      expect(response).to have_http_status(:success)

      # check to make sure the right amount of messages are returned
      expect(json['data'].length).to eq(2)
    end

    it 'identifies the type of labware' do
      api_get base_endpoint
      listed = json['data'].pluck('type').sort
      expect(listed).to eq(%w[tubes tubes])
    end

    # Check filters, ESPECIALLY if they aren't simple attribute filters
  end

  context 'with a request' do
    let(:resource_model) { create(:sample_tube) }

    it 'sends an individual labware' do
      api_get "#{base_endpoint}/#{resource_model.id}"
      expect(response).to have_http_status(:success)
      expect(json.dig('data', 'type')).to eq('tubes')
    end
  end

  context 'with include' do
    let(:custom_metadatum_collection) { create(:custom_metadatum_collection_with_metadata) }
    let(:labware) { custom_metadatum_collection.asset }

    it 'sends an individual labware' do
      api_get "#{base_endpoint}/#{labware.id}?include=custom_metadatum_collection"
      expect(response).to have_http_status(:success)
      expect(json.dig('data', 'type')).to eq('labware')
      expect(json['included'][0]['attributes']['uuid']).to eq(custom_metadatum_collection.uuid)
      expect(json['included'][0]['attributes']['metadata']).to eq(custom_metadatum_collection.metadata)
      expect(json['included'][0]['attributes']['user_id']).to eq(custom_metadatum_collection.user_id)
      expect(json['included'][0]['attributes']['asset_id']).to eq(custom_metadatum_collection.asset_id)
    end
  end
end
