# frozen_string_literal: true

require 'rails_helper'
require './spec/requests/api/v2/shared_examples/api_key_authenticatable'
require './spec/requests/api/v2/shared_examples/requests'

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

    describe '#filter' do
      let(:target_resource) { users[2] }
      let(:target_id) { target_resource.id }

      describe 'by swipecard code' do
        let(:swipecard_code) { '1234567' }

        before do
          target_resource.update(swipecard_code:)
          api_get "#{base_endpoint}?filter[user_code]=#{swipecard_code}"
        end

        it_behaves_like 'it has filtered to a resource with target_id correctly'
      end

      describe 'by barcode' do
        let(:barcode) { '2470041440697' }

        before do
          target_resource.update(barcode: Barcode.barcode_to_human(barcode))
          api_get "#{base_endpoint}?filter[user_code]=#{barcode}"
        end

        it_behaves_like 'it has filtered to a resource with target_id correctly'
      end

      describe 'by uuid' do
        before { api_get "#{base_endpoint}?filter[uuid]=#{target_resource.uuid}" }

        it_behaves_like 'it has filtered to a resource with target_id correctly'
      end
    end
  end

  context 'with a User' do
    let(:resource_model) { create(:user) }

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
    let(:resource_model) { create(:user) }
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

  context 'when DELETE request is unsuccessful' do
    let(:resource) { create(:user) }

    it_behaves_like 'a DESTROY request for a v2 resource'
  end
end
