# frozen_string_literal: true

require 'rails_helper'

describe 'Orders API', with: :api_v2 do
  context 'with multiple orders' do
    before { create_list(:order, 5) }

    it 'sends a list of orders' do
      api_get '/api/v2/orders'

      # test for the 200 status-code
      expect(response).to have_http_status(:success)

      # check to make sure the right amount of messages are returned
      expect(json['data'].length).to eq(5)
    end

    # Check filters, ESPECIALLY if they aren't simple attribute filters
  end

  context 'with a order' do
    let(:resource_model) { create :order }

    let(:payload) do
      {
        'data' => {
          'id' => resource_model.id,
          'type' => 'orders',
          'attributes' => {
            # Set new attributes
          }
        }
      }
    end

    it 'sends an individual order' do
      api_get "/api/v2/orders/#{resource_model.id}"
      expect(response).to have_http_status(:success)
      expect(json.dig('data', 'type')).to eq('orders')
    end

    # Remove if immutable
    it 'allows update of a order' do
      api_patch "/api/v2/orders/#{resource_model.id}", payload
      expect(response).to have_http_status(:success)
      expect(json.dig('data', 'type')).to eq('orders')
      # Double check at least one of the attributes
      # eg. expect(json.dig('data', 'attributes', 'state')).to eq('started')
    end
  end
end
