# frozen_string_literal: true

require 'rails_helper'

describe 'CustomMetadatumCollections API', with: :api_v2 do
  context 'with multiple custom_metadatum_collections' do
    before { create_list(:custom_metadatum_collection, 5) }

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
    let(:resource_model) { create :custom_metadatum_collection_with_metadata }
    let(:user) { create :user }
    let(:asset) { create :asset }

    describe '#get' do
      it 'sends an individual custom_metadatum_collection' do
        api_get "/api/v2/custom_metadatum_collections/#{resource_model.id}"
        expect(response).to have_http_status(:success)
        expect(json.dig('data', 'type')).to eq('custom_metadatum_collections')
        expect(json.dig('data', 'attributes', 'metadata').length).to eq 5
        expect(json.dig('data', 'attributes', 'user_id')).to be_present
        expect(json.dig('data', 'attributes', 'asset_id')).to be_present
      end
    end

    describe '#patch' do
      let(:patch_payload) do
        {
          'data' => {
            'id' => resource_model.id,
            'type' => 'custom_metadatum_collections',
            'attributes' => {
              'metadata': {
                'Key 1': 'Some updated metadata',
                'New key': 'New key also gets added'
              }
            }
          }
        }
      end

      let(:invalid_patch_payload) do
        {
          'data' => {
            'id' => resource_model.id,
            'attributes' => {
              'metadata': {
                'Key 1': 'Some updated metadata',
                'New key': 'New key also gets added'
              }
            }
          }
        }
      end

      # patch replaces all metadata, with that provided
      it 'successfully allows update of a custom_metadatum_collection' do
        expect(resource_model.metadata).to include({ 'Key 1' => 'a bit of metadata' })
        expect(resource_model.metadata.length).to eq 5

        api_patch "/api/v2/custom_metadatum_collections/#{resource_model.id}", patch_payload
        expect(response).to have_http_status(:success)
        expect(json.dig('data', 'type')).to eq('custom_metadatum_collections')
        expect(json.dig('data', 'attributes', 'metadata')).to include({ 'Key 1' => 'Some updated metadata' })
        expect(json.dig('data', 'attributes', 'metadata')).to include({ 'New key' => 'New key also gets added' })
        expect(json.dig('data', 'attributes', 'user_id')).to be_present
        expect(json.dig('data', 'attributes', 'asset_id')).to be_present
        expect(json.dig('data', 'attributes', 'uuid')).to be_present
        resource_model.reload
        expect(resource_model.metadata.length).to eq 2
      end

      it 'does not update of a custom_metadatum_collection when missing attributes' do
        expect(resource_model.metadata).to include({ 'Key 1' => 'a bit of metadata' })
        expect(resource_model.metadata.length).to eq 5

        api_patch "/api/v2/custom_metadatum_collections/#{resource_model.id}", invalid_patch_payload
        expect(response).to have_http_status(400)
        expect(json.dig('errors')[0].dig('title')).to eq('Missing Parameter')
        resource_model.reload
        expect(resource_model.metadata.length).to eq 5
      end
    end

    describe '#post' do
      let(:payload) do
        {
          'data' => {
            'type' => 'custom_metadatum_collections',
            'attributes' => {
              'user_id': '1',
              'asset_id': '1',
              'metadata': {
                'a metadata key': 'a value'
              }
            }
          }
        }
      end

      let(:invalid_payload) do
        {
          'data' => {
            'type' => 'custom_metadatum_collections',
            'attributes' => {
              'user_id': '1',
              'metadata': {
                'a metadata key': 'a value'
              }
            }
          }
        }
      end
      it 'successfully allows creation of a custom_metadatum_collection' do
        api_post '/api/v2/custom_metadatum_collections', payload
        expect(response).to have_http_status(:success), response.body
        expect(json.dig('data', 'type')).to eq('custom_metadatum_collections')
        expect(json.dig('data', 'attributes', 'metadata')).to eq({ 'a metadata key' => 'a value' })
        expect(json.dig('data', 'attributes', 'user_id')).to be_present
        expect(json.dig('data', 'attributes', 'asset_id')).to be_present
        expect(json.dig('data', 'attributes', 'uuid')).to be_present
      end

      it 'does not create a custom_metadatum_collection when missing attribues' do
        api_post '/api/v2/custom_metadatum_collections', invalid_payload
        expect(response).to have_http_status(422)
        expect(json.dig('errors')[0].dig('detail')).to eq("asset_id - can't be blank")
      end
    end
  end
end
