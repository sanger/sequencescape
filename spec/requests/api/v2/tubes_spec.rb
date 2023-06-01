# frozen_string_literal: true

require 'rails_helper'
require './spec/requests/api/v2/shared_examples/api_key_authenticatable'

describe 'Tubes API', with: :api_v2 do
  let(:base_endpoint) { '/api/v2/tubes' }

  it_behaves_like 'ApiKeyAuthenticatable'

  context 'with multiple tubes' do
    before do
      create_list(:tube, 1)
      create_list(:sample_tube, 2)
      create_list(:library_tube, 1)
      create_list(:multiplexed_library_tube, 1)
    end

    it 'sends a list of tubes' do
      api_get base_endpoint

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
      api_get "#{base_endpoint}/#{resource_model.id}"
      expect(response).to have_http_status(:success)
      expect(json.dig('data', 'type')).to eq('tubes')
    end
  end
end
