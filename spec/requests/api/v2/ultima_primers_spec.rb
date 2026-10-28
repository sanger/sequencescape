# frozen_string_literal: true

require 'rails_helper'
require './spec/requests/api/v2/shared_examples/api_key_authenticatable'

describe 'UltimaPrimers API', with: :api_v2 do
  let(:base_endpoint) { '/api/v2/ultima_primers' }
  let(:resource_type) { 'ultima_primers' }

  it_behaves_like 'ApiKeyAuthenticatable'

  context 'with multiple Ultima primers' do
    before do
      create_list(:ultima_primer, 3)
      api_get base_endpoint
    end

    it 'responds with a success http code' do
      expect(response).to have_http_status(:success)
    end

    it 'returns all the Ultima primers' do
      expect(json['data'].length).to eq(3)
    end
  end

  context 'with a single resource' do
    let(:resource) { create(:ultima_primer) }

    before { api_get "#{base_endpoint}/#{resource.id}" }

    it 'responds with a success http code' do
      expect(response).to have_http_status(:success)
    end

    it 'returns the correct resource type' do
      expect(json.dig('data', 'type')).to eq(resource_type)
    end

    it 'returns the name' do
      expect(json.dig('data', 'attributes', 'name')).to eq(resource.name)
    end
  end

  describe '#post a new Ultima primer' do
    let(:payload) { { 'data' => { 'type' => resource_type, 'attributes' => { 'name' => 'UG-tR9' } } } }

    it 'finds no route for the method' do
      expect { api_post base_endpoint, payload }.to raise_error(ActionController::RoutingError)
    end
  end
end
