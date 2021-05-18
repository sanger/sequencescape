# frozen_string_literal: true

require 'rails_helper'

describe 'TransferRequests API', with: :api_v2 do
  context 'with multiple TransferRequests' do
    before { create_list(:transfer_request, 5) }

    it 'sends a list of transfer_requests' do
      api_get '/api/v2/transfer_requests'

      # test for the 200 status-code
      expect(response).to have_http_status(:success)

      # check to make sure the right amount of messages are returned
      expect(json['data'].length).to eq(5)
    end

    # Check filters, ESPECIALLY if they aren't simple attribute filters
  end

  context 'with a TransferRequest' do
    let(:resource_model) { create :transfer_request_with_submission }

    let(:payload) do
      {
        'data' => {
          'id' => resource_model.id,
          'type' => 'transfer_requests',
          'attributes' => {
            'state' => 'started'
          }
        }
      }
    end

    it 'sends an individual TransferRequest' do
      api_get "/api/v2/transfer_requests/#{resource_model.id}"
      expect(response).to have_http_status(:success)
      expect(json.dig('data', 'type')).to eq('transfer_requests')
    end
  end
end
