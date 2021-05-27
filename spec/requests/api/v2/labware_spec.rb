# frozen_string_literal: true

require 'rails_helper'

describe 'Labware API', with: :api_v2 do
  context 'with multiple receptacles of different types' do
    before do
      create(:sample_tube)
      create(:library_tube)
    end

    it 'sends a list of labware' do
      api_get '/api/v2/labware'

      # test for the 200 status-code
      expect(response).to have_http_status(:success)

      # check to make sure the right amount of messages are returned
      expect(json['data'].length).to eq(2)
    end

    it 'identifies the type of labware' do
      api_get '/api/v2/labware'
      listed = json['data'].map { |data| data['type'] }.sort
      expect(listed).to eq(%w[tubes tubes])
    end

    # Check filters, ESPECIALLY if they aren't simple attribute filters
  end

  context 'with a request' do
    let(:resource_model) { create :sample_tube }

    it 'sends an individual labware' do
      api_get "/api/v2/labware/#{resource_model.id}"
      expect(response).to have_http_status(:success)
      expect(json.dig('data', 'type')).to eq('tubes')
    end
  end
end
