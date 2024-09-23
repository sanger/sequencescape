# frozen_string_literal: true

require 'rails_helper'
require './spec/requests/api/v2/shared_examples/api_key_authenticatable'

describe 'Users API', with: :api_v2 do
  let(:base_endpoint) { '/api/v2/users' }

  it_behaves_like 'ApiKeyAuthenticatable'

  context 'with multiple Users' do
    let(:users) { create_list(:user, 5) }

    before { api_get base_endpoint }

    it 'responds with a success HTTP status code' do
      expect(response).to have_http_status(:success)
    end

    it 'responds with all the Users' do
      expect(json['data'].length).to eq User.count
    end

    describe 'filtering' do
      let(:user) { users[2] }

      context 'with a User with a swipecard code' do
        let(:swipecard_code) { '1234567' }

        before do
          user.update(swipecard_code:)
          api_get "#{base_endpoint}?filter[user_code]=#{swipecard_code}"
        end

        it 'responds with a success HTTP status code' do
          expect(response).to have_http_status(:success)
        end

        it 'responds with only the User with the swipecard code' do
          expect(json['data'].length).to eq(1)
          expect(json.dig('data', 0, 'id')).to eq user.id.to_s
        end
      end

      context 'with a User with a barcode' do
        let(:barcode) { '2470041440697' }

        before do
          user.update(barcode: Barcode.barcode_to_human(barcode))
          api_get "#{base_endpoint}?filter[user_code]=#{barcode}"
        end

        it 'responds with a success HTTP status code' do
          expect(response).to have_http_status(:success)
        end

        it 'responds with only the User with the barcode' do
          expect(json['data'].length).to eq(1)
          expect(json.dig('data', 0, 'id')).to eq user.id.to_s
        end
      end

      context 'with a User with a UUID' do
        before { api_get "#{base_endpoint}?filter[uuid]=#{user.uuid}" }

        it 'responds with a success HTTP status code' do
          expect(response).to have_http_status(:success)
        end

        it 'responds with only the User with the UUID' do
          expect(json['data'].length).to eq(1)
          expect(json.dig('data', 0, 'id')).to eq user.id.to_s
        end
      end
    end
  end

  context 'with a User' do
    let(:resource_model) { create :user }

    describe '#get' do
      before { api_get "#{base_endpoint}/#{resource_model.id}" }

      it 'responds with a success HTTP status code' do
        expect(response).to have_http_status(:success)
      end

      it 'responds with the correct data for the User' do
        expect(json.dig('data', 'id')).to eq resource_model.id.to_s
        expect(json.dig('data', 'type')).to eq('users')
        expect(json.dig('data', 'attributes', 'uuid')).to eq resource_model.uuid
        expect(json.dig('data', 'attributes', 'login')).to eq resource_model.login
        expect(json.dig('data', 'attributes', 'first_name')).to eq resource_model.first_name
        expect(json.dig('data', 'attributes', 'last_name')).to eq resource_model.last_name
      end
    end
  end

  describe '#patch' do
    let(:resource_model) { create :user }
    let(:payload) { { 'data' => { 'id' => resource_model.id, 'type' => 'users', 'attributes' => {} } } }

    it 'cannot find a route to the endpoint' do
      expect { api_patch "#{base_endpoint}/#{resource_model.id}", payload }.to raise_error(
        ActionController::RoutingError
      )
    end
  end

  describe '#post' do
    let(:payload) { { 'data' => { 'type' => 'users', 'attributes' => {} } } }

    it 'cannot find a route to the endpoint' do
      expect { api_post base_endpoint, payload }.to raise_error(ActionController::RoutingError)
    end
  end
end
