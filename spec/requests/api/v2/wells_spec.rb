# frozen_string_literal: true

require 'rails_helper'

describe 'Wells API', with: :api_v2 do
  context 'with multiple wells' do
    before do
      create_list(:well, 5)
    end

    it 'sends a list of wells' do
      api_get '/api/v2/wells'
      # test for the 200 status-code
      expect(response).to have_http_status(:success)
      # check to make sure the right amount of messages are returned
      expect(json['data'].length).to eq(5)
    end

    # Check filters, ESPECIALLY if they aren't simple attribute filters
  end

  context 'with a well' do
    let(:resource_model) { create :well }

    it 'sends an individual well' do
      api_get "/api/v2/wells/#{resource_model.id}"
      expect(response).to have_http_status(:success)
      expect(json.dig('data', 'type')).to eq('wells')
    end
  end
end
