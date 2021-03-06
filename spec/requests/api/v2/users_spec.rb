# frozen_string_literal: true

require 'rails_helper'

describe 'Users API', with: :api_v2 do
  context 'with multiple users' do
    let(:swipecard_code) { '1234567' }
    let(:user_barcode) { '2470041440697' }

    before do
      create_list(:user, 5)
      create :user, swipecard_code: swipecard_code
      create :user, barcode: 'ID41440E'
    end

    it 'sends a list of users' do
      api_get '/api/v2/users'

      # test for the 200 status-code
      expect(response).to have_http_status(:success)

      # check to make sure the right amount of messages are returned
      expect(json['data'].length).to eq(7)
    end

    it 'allows filtering of users by user_code with swipecard' do
      api_get "/api/v2/users?filter[user_code]=#{swipecard_code}"

      # test for the 200 status-code
      expect(response).to have_http_status(:success)

      # check to make sure the right amount of messages are returned
      expect(json['data'].length).to eq(1)
    end

    it 'allows filtering of users by user_code with barcode' do
      api_get "/api/v2/users?filter[user_code]=#{user_barcode}"

      # test for the 200 status-code
      expect(response).to have_http_status(:success)

      # check to make sure the right amount of messages are returned
      expect(json['data'].length).to eq(1)
    end
  end

  context 'with a user' do
    let(:resource_model) { create :user }

    it 'sends an individual user' do
      api_get "/api/v2/users/#{resource_model.id}"
      expect(response).to have_http_status(:success)
      expect(json.dig('data', 'type')).to eq('users')
    end
  end
end
