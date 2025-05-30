# frozen_string_literal: true

require 'rails_helper'
require './spec/requests/api/v2/shared_examples/api_key_authenticatable'
require './spec/requests/api/v2/shared_examples/requests'

describe 'SampleMetadata API', with: :api_v2 do
  let(:base_endpoint) { '/api/v2/sample_metadata' }

  it_behaves_like 'ApiKeyAuthenticatable'

  context 'with multiple metadata resources' do
    before { create_list(:sample_metadata_for_api, 5) }

    it 'gets a list of metadata resources' do
      api_get base_endpoint

      expect(response).to have_http_status(:success)
      expect(json['data'].length).to eq(5)
    end
  end

  context 'with a single metadata resource' do
    let(:resource_model) { create(:sample_metadata_for_api) }

    describe '#get' do
      it 'generates a success response' do
        api_get "#{base_endpoint}/#{resource_model.id}"

        expect(response).to have_http_status(:success)
      end

      it 'returns the expected JSON' do
        api_get "#{base_endpoint}/#{resource_model.id}"

        expect(json.dig('data', 'type')).to eq('sample_metadata')
        expect(json.dig('data', 'attributes', 'cohort')).to eq resource_model.cohort
        expect(json.dig('data', 'attributes', 'collected_by')).to eq resource_model.collected_by
        expect(json.dig('data', 'attributes', 'concentration')).to eq resource_model.concentration
        expect(json.dig('data', 'attributes', 'donor_id')).to eq resource_model.donor_id
        expect(json.dig('data', 'attributes', 'gender')).to eq resource_model.gender
        expect(json.dig('data', 'attributes', 'sample_common_name')).to eq resource_model.sample_common_name
        expect(json.dig('data', 'attributes', 'sample_description')).to eq resource_model.sample_description
        expect(json.dig('data', 'attributes', 'supplier_name')).to eq resource_model.supplier_name
        expect(json.dig('data', 'attributes', 'volume')).to eq resource_model.volume
      end
    end

    describe '#patch' do
      context 'with a valid payload' do
        let(:payload) do
          {
            'data' => {
              'id' => resource_model.id,
              'type' => 'sample_metadata',
              'attributes' => {
                cohort: 'updated cohort',
                collected_by: 'updated collected_by',
                concentration: 'updated concentration',
                donor_id: 'updated donor_id',
                gender: 'female',
                sample_common_name: 'updated sample_common_name',
                sample_description: 'updated sample_description',
                supplier_name: 'updated supplier_name',
                volume: 'updated volume'
              }
            }
          }
        end

        it 'gives a success response' do
          api_patch "#{base_endpoint}/#{resource_model.id}", payload

          expect(response).to have_http_status(:success)
        end

        it 'responds with the expected attributes' do
          api_patch "#{base_endpoint}/#{resource_model.id}", payload

          expect(response).to have_http_status(:success)
          expect(json.dig('data', 'attributes', 'cohort')).to eq 'updated cohort'
          expect(json.dig('data', 'attributes', 'collected_by')).to eq 'updated collected_by'
          expect(json.dig('data', 'attributes', 'concentration')).to eq 'updated concentration'
          expect(json.dig('data', 'attributes', 'donor_id')).to eq 'updated donor_id'
          expect(json.dig('data', 'attributes', 'gender')).to eq 'Female'
          expect(json.dig('data', 'attributes', 'sample_common_name')).to eq 'updated sample_common_name'
          expect(json.dig('data', 'attributes', 'sample_description')).to eq 'updated sample_description'
          expect(json.dig('data', 'attributes', 'supplier_name')).to eq 'updated supplier_name'
          expect(json.dig('data', 'attributes', 'volume')).to eq 'updated volume'
        end

        it 'updates the model correctly' do
          # Apply the patch which replaced all the metadata
          api_patch "#{base_endpoint}/#{resource_model.id}", payload

          # Check that the model was modified
          resource_model.reload
          expect(resource_model.cohort).to eq 'updated cohort'
          expect(resource_model.collected_by).to eq 'updated collected_by'
          expect(resource_model.concentration).to eq 'updated concentration'
          expect(resource_model.donor_id).to eq 'updated donor_id'
          expect(resource_model.gender).to eq 'Female'
          expect(resource_model.sample_common_name).to eq 'updated sample_common_name'
          expect(resource_model.sample_description).to eq 'updated sample_description'
          expect(resource_model.supplier_name).to eq 'updated supplier_name'
          expect(resource_model.volume).to eq 'updated volume'
        end
      end

      context 'with a missing type in the payload' do
        let(:payload) { { 'data' => { 'id' => resource_model.id, 'attributes' => { cohort: 'updated cohort' } } } }

        it 'does not update the collection' do
          original_cohort = resource_model.cohort

          api_patch "#{base_endpoint}/#{resource_model.id}", payload
          expect(response).to have_http_status(:bad_request)
          expect(json['errors'][0]['title']).to eq('Missing Parameter')

          # Check that the model was not modified
          resource_model.reload
          expect(resource_model.cohort).to eq original_cohort
        end
      end
    end

    describe '#post' do
      context 'with a valid payload' do
        let(:payload) do
          {
            'data' => {
              'type' => 'sample_metadata',
              'attributes' => {
                cohort: 'posted cohort',
                collected_by: 'posted collected_by',
                concentration: 'posted concentration',
                donor_id: 'posted donor_id',
                gender: 'mixed',
                sample_common_name: 'posted sample_common_name',
                sample_description: 'posted sample_description',
                supplier_name: 'posted supplier_name',
                volume: 'posted volume'
              }
            }
          }
        end

        it 'gives a success response' do
          api_post base_endpoint, payload

          expect(response).to have_http_status(:success)
        end

        it 'creates the resource' do
          expect { api_post base_endpoint, payload }.to change(Sample::Metadata, :count).by(1)
        end

        it 'responds with the correct attributes' do
          api_post base_endpoint, payload

          expect(json.dig('data', 'attributes', 'cohort')).to eq 'posted cohort'
          expect(json.dig('data', 'attributes', 'collected_by')).to eq 'posted collected_by'
          expect(json.dig('data', 'attributes', 'concentration')).to eq 'posted concentration'
          expect(json.dig('data', 'attributes', 'donor_id')).to eq 'posted donor_id'
          expect(json.dig('data', 'attributes', 'gender')).to eq 'Mixed'
          expect(json.dig('data', 'attributes', 'sample_common_name')).to eq 'posted sample_common_name'
          expect(json.dig('data', 'attributes', 'sample_description')).to eq 'posted sample_description'
          expect(json.dig('data', 'attributes', 'supplier_name')).to eq 'posted supplier_name'
          expect(json.dig('data', 'attributes', 'volume')).to eq 'posted volume'
        end

        it 'populates the model correctly' do
          api_post base_endpoint, payload

          new_model = Sample::Metadata.last
          expect(new_model.cohort).to eq 'posted cohort'
          expect(new_model.collected_by).to eq 'posted collected_by'
          expect(new_model.concentration).to eq 'posted concentration'
          expect(new_model.donor_id).to eq 'posted donor_id'
          expect(new_model.gender).to eq 'Mixed'
          expect(new_model.sample_common_name).to eq 'posted sample_common_name'
          expect(new_model.sample_description).to eq 'posted sample_description'
          expect(new_model.supplier_name).to eq 'posted supplier_name'
          expect(new_model.volume).to eq 'posted volume'
        end
      end

      context 'with unexpected "birthday" attribute in the payload' do
        let(:payload) { { 'data' => { 'type' => 'sample_metadata', 'attributes' => { birthday: '14-04-1954' } } } }

        it 'does not create the resource' do
          expect { api_post base_endpoint, payload }.not_to change(Sample::Metadata, :count)

          expect(response).to have_http_status(:bad_request)
          expect(json['errors'][0]['detail']).to eq('birthday is not allowed.') # Sad times :(
        end
      end
    end
  end
end
