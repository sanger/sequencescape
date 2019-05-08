# frozen_string_literal: true

require 'rails_helper'

describe 'CustomMetadatumCollections API', with: :api_v2 do
  context 'with multiple custom_metadatum_collections' do
    before do
      create_list(:custom_metadatum_collection, 5)
    end

    it 'sends a list of custom_metadatum_collections' do
      api_get '/api/v2/custom_metadatum_collections'
      # test for the 200 status-code
      expect(response).to have_http_status(:success)
      # check to make sure the right amount of messages are returned
      expect(json['data'].length).to eq(5)
    end

    # Check filters, ESPECIALLY if they aren't simple attribute filters
  end

  context 'with a custom_metadatum_collection' do
    let(:resource_model) { create :custom_metadatum_collection }

    let(:payload) do
      {
        'data' => {
          'id' => resource_model.id,
          'type' => 'custom_metadatum_collections',
          'attributes' => {
            # Set new attributes
          }
        }
      }
    end

    it 'sends an individual custom_metadatum_collection' do
      api_get "/api/v2/custom_metadatum_collections/#{resource_model.id}"
      expect(response).to have_http_status(:success)
      expect(json.dig('data', 'type')).to eq('custom_metadatum_collections')
    end

    # Remove if immutable
    it 'allows update of a custom_metadatum_collection' do
      api_patch "/api/v2/custom_metadatum_collections/#{resource_model.id}", payload
      expect(response).to have_http_status(:success)
      expect(json.dig('data', 'type')).to eq('custom_metadatum_collections')
      # Double check at least one of the attributes
      # eg. expect(json.dig('data', 'attributes', 'state')).to eq('started')
    end
  end
end
