# frozen_string_literal: true

require 'rails_helper'
require './spec/requests/api/v2/shared_examples/api_key_authenticatable'

describe 'Users API', with: :api_v2 do
  let(:base_endpoint) { '/api/v2/users' }

  it_behaves_like 'ApiKeyAuthenticatable'

  context 'with multiple users' do
    let(:swipecard_code) { '1234567' }
    let(:user_barcode) { '2470041440697' }

    before do
      create_list(:user, 5)
      create :user, swipecard_code: swipecard_code
      create :user, barcode: 'ID41440E'
    end

    it 'sends a list of users' do
      api_get base_endpoint

      # test for the 200 status-code
      expect(response).to have_http_status(:success)

      # check to make sure the right amount of messages are returned
      expect(json['data'].length).to eq(7)
    end

    it 'allows filtering of users by user_code with swipecard' do
      api_get "#{base_endpoint}?filter[user_code]=#{swipecard_code}"

      # test for the 200 status-code
      expect(response).to have_http_status(:success)

      # check to make sure the right amount of messages are returned
      expect(json['data'].length).to eq(1)
    end

    it 'allows filtering of users by user_code with barcode' do
      api_get "#{base_endpoint}?filter[user_code]=#{user_barcode}"

      # test for the 200 status-code
      expect(response).to have_http_status(:success)

      # check to make sure the right amount of messages are returned
      expect(json['data'].length).to eq(1)
    end
  end

  context 'with a user' do
    let(:resource_model) { create :user }

    it 'sends an individual user' do
      api_get "#{base_endpoint}/#{resource_model.id}"
      expect(response).to have_http_status(:success)
      expect(json.dig('data', 'type')).to eq('users')
    end
  end
end
