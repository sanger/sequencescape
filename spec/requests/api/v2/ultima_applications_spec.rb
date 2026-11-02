# frozen_string_literal: true

require 'rails_helper'
require './spec/requests/api/v2/shared_examples/api_key_authenticatable'
require './spec/requests/api/v2/shared_examples/requests'

describe 'UltimaApplications API', with: :api_v2 do
  let(:model_class) { UltimaApplication }
  let(:base_endpoint) { '/api/v2/ultima_applications' }
  let(:resource_type) { 'ultima_applications' }

  it_behaves_like 'ApiKeyAuthenticatable'

  context 'with multiple Ultima applications' do
    before do
      create_list(:ultima_application, 3)
      api_get base_endpoint
    end

    it 'responds with a success http code' do
      expect(response).to have_http_status(:success)
    end

    it 'returns all the Ultima applications' do
      expect(json['data'].length).to eq(3)
    end
  end

  context 'when filtering by name' do
    let!(:application) { create(:ultima_application, name: '10x Flex') }

    before do
      create_list(:ultima_application, 2)
      api_get "#{base_endpoint}?filter[name]=10x%20Flex"
    end

    it 'responds with a success http code' do
      expect(response).to have_http_status(:success)
    end

    it 'returns only the matching Ultima application' do
      expect(json['data'].pluck('id')).to eq([application.id.to_s])
    end
  end

  context 'with a single resource' do
    let(:resource) { create(:ultima_application) }

    context 'without included relationships' do
      before { api_get "#{base_endpoint}/#{resource.id}" }

      it 'responds with a success http code' do
        expect(response).to have_http_status(:success)
      end

      it 'returns the correct resource id' do
        expect(json.dig('data', 'id')).to eq(resource.id.to_s)
      end

      it 'returns the correct resource type' do
        expect(json.dig('data', 'type')).to eq(resource_type)
      end

      it 'returns the name' do
        expect(json.dig('data', 'attributes', 'name')).to eq(resource.name)
      end

      it 'returns the description' do
        expect(json.dig('data', 'attributes', 'description')).to eq(resource.description)
      end
    end

    context 'with included relationships' do
      it_behaves_like 'a GET request including a has_one relationship', 'uga_primer'
      it_behaves_like 'a GET request including a has_one relationship', 'ugb_primer'
    end

    context 'when including both primers' do
      let(:included_primers) do
        json['included'].to_h { |item| [item['id'], item.dig('attributes', 'name')] }
      end

      before { api_get "#{base_endpoint}/#{resource.id}?include=uga_primer,ugb_primer" }

      it 'responds with a success http code' do
        expect(response).to have_http_status(:success)
      end

      it 'returns the UGA primer name' do
        uga_primer_id = json.dig('data', 'relationships', 'uga_primer', 'data', 'id')
        expect(included_primers[uga_primer_id]).to eq(resource.uga_primer.name)
      end

      it 'returns the UGB primer name' do
        ugb_primer_id = json.dig('data', 'relationships', 'ugb_primer', 'data', 'id')
        expect(included_primers[ugb_primer_id]).to eq(resource.ugb_primer.name)
      end
    end
  end

  describe '#post a new Ultima application' do
    let(:payload) { { 'data' => { 'type' => resource_type, 'attributes' => { 'name' => 'New Name' } } } }

    it 'finds no route for the method' do
      expect { api_post base_endpoint, payload }.to raise_error(ActionController::RoutingError)
    end
  end

  describe '#patch an Ultima application' do
    let(:resource) { create(:ultima_application) }
    let(:payload) do
      { 'data' => { 'id' => resource.id, 'type' => resource_type, 'attributes' => { 'name' => 'Updated Name' } } }
    end

    it 'finds no route for the method' do
      expect { api_patch "#{base_endpoint}/#{resource.id}", payload }.to raise_error(ActionController::RoutingError)
    end
  end
end
