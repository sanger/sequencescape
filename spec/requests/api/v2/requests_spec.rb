# frozen_string_literal: true

require 'rails_helper'
require './spec/requests/api/v2/shared_examples/api_key_authenticatable'

describe 'Requests API', with: :api_v2 do
  let(:base_endpoint) { '/api/v2/requests' }

  it_behaves_like 'ApiKeyAuthenticatable'

  context 'with multiple requests' do
    before { create_list(:request, 5) }

    it 'sends a list of requests' do
      api_get base_endpoint

      # test for the 200 status-code
      expect(response).to have_http_status(:success)

      # check to make sure the right amount of messages are returned
      expect(json['data'].length).to eq(5)
    end

    # Check filters, ESPECIALLY if they aren't simple attribute filters
  end

  context 'with a request' do
    let(:resource_model) { create(:request) }

    it 'sends an individual request' do
      api_get "#{base_endpoint}/#{resource_model.id}?include=primer_panel"
      expect(response).to have_http_status(:success)
      expect(json.dig('data', 'type')).to eq('requests')
    end

    it 'handles pre-capture pool inclusion' do
      api_get "#{base_endpoint}/#{resource_model.id}?include=pre_capture_pool"
      expect(response).to have_http_status(:success), response.body
      expect(json.dig('data', 'type')).to eq('requests')
    end
  end
end
