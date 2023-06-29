# frozen_string_literal: true

require 'rails_helper'
require './spec/requests/api/v2/shared_examples/api_key_authenticatable'

describe 'RequestTypes API', with: :api_v2 do
  let(:base_endpoint) { '/api/v2/request_types' }

  it_behaves_like 'ApiKeyAuthenticatable'

  context 'with multiple request_types' do
    before { create_list(:request_type, 5) }

    it 'sends a list of request_types' do
      api_get base_endpoint

      # test for the 200 status-code
      expect(response).to have_http_status(:success)

      # check to make sure the right amount of messages are returned
      expect(json['data'].length).to eq(RequestType.count)
    end

    # Check filters, ESPECIALLY if they aren't simple attribute filters
  end

  context 'with a request_type' do
    let(:resource_model) { create :request_type }

    it 'sends an individual request_type' do
      api_get "#{base_endpoint}/#{resource_model.id}"
      expect(response).to have_http_status(:success)
      expect(json.dig('data', 'type')).to eq('request_types')
    end
  end
end
