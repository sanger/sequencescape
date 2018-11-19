# frozen_string_literal: true

require 'rails_helper'

describe 'Requests API', with: :api_v2 do
  context 'with multiple requests' do
    before do
      create_list(:request, 5)
    end

    it 'sends a list of requests' do
      api_get '/api/v2/requests'
      # test for the 200 status-code
      expect(response).to have_http_status(:success)
      # check to make sure the right amount of messages are returned
      expect(json['data'].length).to eq(5)
    end

    # Check filters, ESPECIALLY if they aren't simple attribute filters

    it 'filters by state' do
      create_list(:request, 5, state: 'started')
      api_get '/api/v2/requests?filter[state]=started'
      expect(response).to have_http_status(:success)
      expect(json['data'].length).to eq(5)
    end

    it 'filters by request type' do
      create_list(:request, 5, request_type: create(:request_type, key: 'long_read'))
      api_get '/api/v2/requests?filter[type]=long_read'
      expect(response).to have_http_status(:success)
      expect(json['data'].length).to eq(5)
    end
  end

  context 'with a request' do
    let(:resource_model) { create :request }

    it 'sends an individual request' do
      api_get "/api/v2/requests/#{resource_model.id}?include=primer_panel"
      expect(response).to have_http_status(:success)
      expect(json.dig('data', 'type')).to eq('requests')
    end

    it 'handles pre-capture pool inclusion' do
      api_get "/api/v2/requests/#{resource_model.id}?include=pre_capture_pool"
      expect(response).to have_http_status(:success), response.body
      expect(json.dig('data', 'type')).to eq('requests')
    end
  end
end
