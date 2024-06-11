# frozen_string_literal: true

require 'rails_helper'
require './spec/requests/api/v2/shared_examples/api_key_authenticatable'

describe 'Poly Metadata API', with: :api_v2 do
  let(:base_endpoint) { '/api/v2/poly_metadata' }

  it_behaves_like 'ApiKeyAuthenticatable'

  context 'with multiple PolyMetadata' do
    before { create_list(:poly_metadatum, 5) }

    it 'sends a list of poly metadata' do
      api_get base_endpoint

      # test for the 200 status-code
      expect(response).to have_http_status(:success)

      # check to make sure the right amount of messages are returned
      expect(json['data'].length).to eq(5)
    end

    # Check filters, ESPECIALLY if they aren't simple attribute filters
  end

  context 'with a PolyMetadatum' do
    let(:resource_model) { create(:poly_metadatum) }

    let(:payload) do
      {
        'data' => {
          'id' => resource_model.id,
          'type' => 'poly_metadata',
          'attributes' => {
            # Set new attributes
            value: 'some_value_1_updated'
          }
        }
      }
    end

    it 'sends an individual PolyMetadatum' do
      api_get "#{base_endpoint}/#{resource_model.id}"
      expect(response).to have_http_status(:success)
      expect(json.dig('data', 'type')).to eq('poly_metadata')
    end

    # check we can update the resource
    it 'allows update of a PolyMetadatum' do
      api_patch "#{base_endpoint}/#{resource_model.id}", payload
      expect(response).to have_http_status(:success)
      expect(json.dig('data', 'type')).to eq('poly_metadata')

      # check key unchanged
      expect(json.dig('data', 'attributes', 'key')).to eq('some_key_1')

      # check value updated
      expect(json.dig('data', 'attributes', 'value')).to eq('some_value_1_updated')
    end
  end

  describe '#post' do
    let(:plate) { create(:plate) }
    let!(:request) { create(:well_request, asset: plate.wells.first) }

    let(:payload) do
      {
        'data' => {
          'type' => 'poly_metadata',
          'attributes' => {
            'key' => 'test_key',
            'value' => 'test_value'
          },
          'relationships' => {
            'metadatable' => {
              'data' => {
                'type' => 'Request',
                'id' => request.id.to_s
              }
            }
          }
        }
      }
    end

    it 'allows creation of a PolyMetadatum' do
      api_post base_endpoint, payload
      expect(response).to have_http_status(:success), response.body
      expect(json.dig('data', 'type')).to eq('poly_metadata')
      expect(json.dig('data', 'attributes', 'value')).to eq('test_value')
    end
  end
end
