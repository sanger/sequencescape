# frozen_string_literal: true

require 'rails_helper'
require './spec/requests/api/v2/shared_examples/api_key_authenticatable'

describe 'LotTypes API', with: :api_v2 do
  let(:base_endpoint) { '/api/v2/lot_types' }

  it_behaves_like 'ApiKeyAuthenticatable'

  context 'with multiple LotTypes' do
    before { create_list(:lot_type, 5) }

    it 'sends a list of lot_types' do
      api_get base_endpoint

      # test for the 200 status-code
      expect(response).to have_http_status(:success)

      # check to make sure the right amount of messages are returned
      expect(json['data'].length).to eq(5)
    end

    # Check filters, ESPECIALLY if they aren't simple attribute filters
  end

  context 'with a LotType' do
    let(:resource_model) { create(:lot_type) }

    let(:payload) do
      {
        'data' => {
          'id' => resource_model.id,
          'type' => 'lot_types',
          'attributes' => {
            # Set new attributes
          }
        }
      }
    end

    it 'sends an individual LotType' do
      api_get "#{base_endpoint}/#{resource_model.id}"
      expect(response).to have_http_status(:success)
      expect(json.dig('data', 'type')).to eq('lot_types')
    end
  end
end
