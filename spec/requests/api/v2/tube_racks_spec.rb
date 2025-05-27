# frozen_string_literal: true

require 'rails_helper'
require './spec/requests/api/v2/shared_examples/api_key_authenticatable'
require './spec/requests/api/v2/shared_examples/requests'

describe 'TubeRacks API', with: :api_v2 do
  let(:base_endpoint) { '/api/v2/tube_racks' }

  it_behaves_like 'ApiKeyAuthenticatable'

  context 'with multiple TubeRacks' do
    before { create_list(:tube_rack, 5) }

    it 'sends a list of tube_racks' do
      api_get base_endpoint

      # test for the 200 status-code
      expect(response).to have_http_status(:success)

      # check to make sure the right amount of messages are returned
      expect(json['data'].length).to eq(5)
    end

    # Check filters, ESPECIALLY if they aren't simple attribute filters
  end

  context 'with a TubeRack' do
    let(:resource_model) { create(:tube_rack) }

    let(:payload) do
      {
        'data' => {
          'id' => resource_model.id,
          'type' => 'tube_racks',
          'attributes' => {
            # Set new attributes
          }
        }
      }
    end

    it 'sends an individual TubeRack' do
      api_get "#{base_endpoint}/#{resource_model.id}"
      expect(response).to have_http_status(:success)
      expect(json.dig('data', 'type')).to eq('tube_racks')
    end

    # Remove if immutable
    it 'allows update of a TubeRack' do
      api_patch "#{base_endpoint}/#{resource_model.id}", payload
      expect(response).to have_http_status(:success)
      expect(json.dig('data', 'type')).to eq('tube_racks')
      # Double check at least one of the attributes
      # eg. expect(json.dig('data', 'attributes', 'state')).to eq('started')
    end
  end

  context 'when DELETE request is unsuccessful' do
    let(:resource) { create(:tube_rack) }

    it_behaves_like 'a DESTROY request for a v2 resource'
  end
end
