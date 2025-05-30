# frozen_string_literal: true

require 'rails_helper'
require './spec/requests/api/v2/shared_examples/api_key_authenticatable'
require './spec/requests/api/v2/shared_examples/requests'

describe 'CustomMetadatumCollections API', with: :api_v2 do
  let(:base_endpoint) { '/api/v2/custom_metadatum_collections' }

  it_behaves_like 'ApiKeyAuthenticatable'

  context 'with multiple collections' do
    before { create_list(:custom_metadatum_collection, 5) }

    it 'gets a list of collections' do
      api_get base_endpoint

      expect(response).to have_http_status(:success)
      expect(json['data'].length).to eq(5)
    end
  end

  context 'with a collection' do
    let(:resource_model) { create(:custom_metadatum_collection_with_metadata) }
    let(:user) { create(:user) }
    let(:asset) { create(:asset) }

    describe '#get' do
      it 'responds with success' do
        api_get "#{base_endpoint}/#{resource_model.id}"

        expect(response).to have_http_status(:success)
      end

      it 'responds with the correct type' do
        api_get "#{base_endpoint}/#{resource_model.id}"

        expect(json.dig('data', 'type')).to eq('custom_metadatum_collections')
      end

      it 'gets the expected attribute values' do
        api_get "#{base_endpoint}/#{resource_model.id}"

        expect(response).to have_http_status(:success)
        expect(json.dig('data', 'attributes', 'uuid')).to eq resource_model.uuid
        expect(json.dig('data', 'attributes', 'metadata').length).to eq resource_model.metadata.length
        expect(json.dig('data', 'attributes', 'user_id')).to eq resource_model.user_id
        expect(json.dig('data', 'attributes', 'asset_id')).to eq resource_model.asset_id
      end
    end

    describe '#patch' do
      context 'with a valid payload' do
        let(:payload) do
          {
            'data' => {
              'id' => resource_model.id,
              'type' => 'custom_metadatum_collections',
              'attributes' => {
                metadata: {
                  'Key 1': 'Some updated metadata',
                  'New key': 'New key also gets added'
                }
              }
            }
          }
        end

        it 'responds with success' do
          api_patch "#{base_endpoint}/#{resource_model.id}", payload

          expect(response).to have_http_status(:success)
        end

        it 'responds with the correct type' do
          api_patch "#{base_endpoint}/#{resource_model.id}", payload

          expect(json.dig('data', 'type')).to eq('custom_metadatum_collections')
        end

        it 'responds with the updated attributes' do
          api_patch "#{base_endpoint}/#{resource_model.id}", payload

          expect(json.dig('data', 'attributes', 'metadata')).to include({ 'Key 1' => 'Some updated metadata' })
          expect(json.dig('data', 'attributes', 'metadata')).to include({ 'New key' => 'New key also gets added' })
          expect(json.dig('data', 'attributes', 'user_id')).to be_present
          expect(json.dig('data', 'attributes', 'asset_id')).to be_present
          expect(json.dig('data', 'attributes', 'uuid')).to be_present
        end

        it 'updates the collection correctly' do
          # Check the initial state of the model
          expect(resource_model.metadata).to include({ 'Key 1' => 'a bit of metadata' })
          expect(resource_model.metadata.length).to eq 5

          # Apply the patch which replaced all the metadata
          api_patch "#{base_endpoint}/#{resource_model.id}", payload

          # Check that the model was modified
          resource_model.reload
          expect(resource_model.metadata).to include({ 'Key 1' => 'Some updated metadata' })
          expect(resource_model.metadata.length).to eq 2
        end
      end

      context 'with a missing type in the payload' do
        let(:payload) do
          {
            'data' => {
              'id' => resource_model.id,
              'attributes' => {
                metadata: {
                  'Key 1': 'Some updated metadata',
                  'New key': 'New key also gets added'
                }
              }
            }
          }
        end

        it 'responds with bad request' do
          api_patch "#{base_endpoint}/#{resource_model.id}", payload

          expect(response).to have_http_status(:bad_request)
        end

        it 'responds with the correct error message' do
          api_patch "#{base_endpoint}/#{resource_model.id}", payload

          expect(json['errors'][0]['title']).to eq('Missing Parameter')
        end

        it 'does not update the model' do
          api_patch "#{base_endpoint}/#{resource_model.id}", payload

          resource_model.reload
          expect(resource_model.metadata.length).to eq 5
        end
      end

      context 'with disallowed attributes' do
        let(:attributes) { {} }
        let(:payload) do
          {
            'data' => {
              'id' => resource_model.id,
              'type' => 'custom_metadatum_collections',
              'attributes' => attributes
            }
          }
        end

        context 'with a uuid in the payload' do
          let(:attributes) { { uuid: '111111-2222-3333-4444-555555666666' } }

          it 'responds with bad request' do
            api_patch "#{base_endpoint}/#{resource_model.id}", payload

            expect(response).to have_http_status(:bad_request)
          end

          it 'responds with the correct error message' do
            api_patch "#{base_endpoint}/#{resource_model.id}", payload

            expect(json['errors'][0]['title']).to eq('Param not allowed')
          end

          it 'does not update the resource' do
            orig_length = resource_model.metadata.length

            api_patch "#{base_endpoint}/#{resource_model.id}", payload

            # Check that the model was not modified
            resource_model.reload
            expect(resource_model.metadata.length).to eq orig_length
          end
        end

        context 'with a user_id in the payload' do
          let(:attributes) { { user_id: 1 } }

          it 'responds with bad request' do
            api_patch "#{base_endpoint}/#{resource_model.id}", payload

            expect(response).to have_http_status(:bad_request)
          end

          it 'responds with the correct error message' do
            api_patch "#{base_endpoint}/#{resource_model.id}", payload

            expect(json['errors'][0]['title']).to eq('Param not allowed')
          end

          it 'does not update the resource' do
            orig_length = resource_model.metadata.length

            api_patch "#{base_endpoint}/#{resource_model.id}", payload

            # Check that the model was not modified
            resource_model.reload
            expect(resource_model.metadata.length).to eq orig_length
          end
        end

        context 'with an asset_id in the payload' do
          let(:attributes) { { asset_id: 1 } }

          it 'responds with bad request' do
            api_patch "#{base_endpoint}/#{resource_model.id}", payload

            expect(response).to have_http_status(:bad_request)
          end

          it 'responds with the correct error message' do
            api_patch "#{base_endpoint}/#{resource_model.id}", payload

            expect(json['errors'][0]['title']).to eq('Param not allowed')
          end

          it 'does not update the collection' do
            orig_length = resource_model.metadata.length

            api_patch "#{base_endpoint}/#{resource_model.id}", payload

            # Check that the model was not modified
            resource_model.reload
            expect(resource_model.metadata.length).to eq orig_length
          end
        end
      end
    end
  end

  describe '#post' do
    context 'with a valid payload' do
      let(:payload) do
        {
          'data' => {
            'type' => 'custom_metadatum_collections',
            'attributes' => {
              user_id: 1,
              asset_id: 1,
              metadata: {
                'a metadata key': 'a value'
              }
            }
          }
        }
      end

      it 'creates a new resource' do
        expect { api_post base_endpoint, payload }.to change(CustomMetadatumCollection, :count).by(1)
      end

      it 'responds with success' do
        api_post base_endpoint, payload

        expect(response).to have_http_status(:success)
      end

      it 'responds with the correct attributes' do
        api_post base_endpoint, payload

        expect(json.dig('data', 'type')).to eq('custom_metadatum_collections')
        expect(json.dig('data', 'attributes', 'metadata')).to eq({ 'a metadata key' => 'a value' })
        expect(json.dig('data', 'attributes', 'user_id')).to eq 1
        expect(json.dig('data', 'attributes', 'asset_id')).to eq 1
        expect(json.dig('data', 'attributes', 'uuid')).to be_present
      end

      it 'applies the attributes to the new record' do
        api_post base_endpoint, payload

        new_record = CustomMetadatumCollection.last
        expect(new_record.metadata).to eq({ 'a metadata key' => 'a value' })
        expect(new_record.user_id).to eq 1
        expect(new_record.asset_id).to eq 1
      end
    end

    context 'with missing asset_id in the payload' do
      let(:payload) do
        {
          'data' => {
            'type' => 'custom_metadatum_collections',
            'attributes' => {
              user_id: 1,
              metadata: {
                'a metadata key': 'a value'
              }
            }
          }
        }
      end

      it 'does not create a new resource' do
        expect { api_post base_endpoint, payload }.not_to change(CustomMetadatumCollection, :count)
      end

      it 'responds with unprocessable entity' do
        api_post base_endpoint, payload

        expect(response).to have_http_status(:unprocessable_entity)
      end

      it 'responds with the correct error' do
        api_post base_endpoint, payload

        expect(json['errors'][0]['detail']).to eq("asset_id - can't be blank")
      end
    end

    context 'with a uuid in the payload' do
      let(:payload) do
        {
          'data' => {
            'type' => 'custom_metadatum_collections',
            'attributes' => {
              uuid: '111111-2222-3333-4444-555555666666',
              user_id: 1,
              asset_id: 1,
              metadata: {
                'a metadata key': 'a value'
              }
            }
          }
        }
      end

      it 'does not create a new resource' do
        expect { api_post base_endpoint, payload }.not_to change(CustomMetadatumCollection, :count)
      end

      it 'responds with bad request' do
        api_post base_endpoint, payload

        expect(response).to have_http_status(:bad_request)
      end

      it 'responds with the correct error' do
        api_post base_endpoint, payload

        expect(json['errors'][0]['detail']).to eq('uuid is not allowed.')
      end
    end
  end
end
