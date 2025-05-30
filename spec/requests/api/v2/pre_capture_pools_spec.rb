# frozen_string_literal: true

require 'rails_helper'
require './spec/requests/api/v2/shared_examples/api_key_authenticatable'
require './spec/requests/api/v2/shared_examples/requests'

describe 'PreCapturePools API', with: :api_v2 do
  let(:base_endpoint) { '/api/v2/pre_capture_pools' }

  it_behaves_like 'ApiKeyAuthenticatable'

  context 'with multiple pre_capture_pools' do
    before { create_list(:pre_capture_pool, 5) }

    it 'sends a list of pre_capture_pools' do
      api_get base_endpoint

      # test for the 200 status-code
      expect(response).to have_http_status(:success)

      # check to make sure the right amount of messages are returned
      expect(json['data'].length).to eq(5)
    end

    # Check filters, ESPECIALLY if they aren't simple attribute filters
  end

  context 'with a pre_capture_pool' do
    let(:resource_model) { create(:pre_capture_pool) }

    let(:payload) do
      {
        'data' => {
          'id' => resource_model.id,
          'type' => 'pre_capture_pools',
          'attributes' => {
            # Set new attributes
          }
        }
      }
    end

    it 'sends an individual pre_capture_pool' do
      api_get "#{base_endpoint}/#{resource_model.id}"
      expect(response).to have_http_status(:success)
      expect(json.dig('data', 'type')).to eq('pre_capture_pools')
    end

    # Remove if immutable
    it 'allows update of a pre_capture_pool' do
      api_patch "#{base_endpoint}/#{resource_model.id}", payload
      expect(response).to have_http_status(:success)
      expect(json.dig('data', 'type')).to eq('pre_capture_pools')
      # Double check at least one of the attributes
      # eg. expect(json.dig('data', 'attributes', 'state')).to eq('started')
    end
  end
end
