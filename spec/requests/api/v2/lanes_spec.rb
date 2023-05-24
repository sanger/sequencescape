# frozen_string_literal: true

require 'rails_helper'

describe 'Lanes API', with: :api_v2 do
  let(:base_endpoint) { '/api/v2/lanes' }

  context 'with multiple lanes' do
    before { create_list(:lane, 5) }

    it 'sends a list of lanes' do
      api_get base_endpoint

      # test for the 200 status-code
      expect(response).to have_http_status(:success)

      # check to make sure the right amount of messages are returned
      expect(json['data'].length).to eq(5)
    end

    # Check filters, ESPECIALLY if they aren't simple attribute filters
  end

  context 'with a lane' do
    let(:resource_model) { create :lane }

    it 'sends an individual lane' do
      api_get "#{base_endpoint}/#{resource_model.id}"
      expect(response).to have_http_status(:success)
      expect(json.dig('data', 'type')).to eq('lanes')
    end
  end
end
