# frozen_string_literal: true

require 'rails_helper'

describe 'Tubes API', with: :api_v2 do
  context 'with multiple tubes' do
    before do
      create_list(:tube, 5)
    end

    it 'sends a list of tubes' do
      api_get '/api/v2/tubes'
      # test for the 200 status-code
      expect(response).to have_http_status(:success)
      # check to make sure the right amount of messages are returned
      expect(json['data'].length).to eq(5)
    end

    # Check filters, ESPECIALLY if they aren't simple attribute filters
  end

  context 'with a tube' do
    let(:resource_model) { create :tube }

    it 'sends an individual tube' do
      api_get "/api/v2/tubes/#{resource_model.id}"
      expect(response).to have_http_status(:success)
      expect(json.dig('data', 'type')).to eq('tubes')
    end
  end
end
