# frozen_string_literal: true

require 'rails_helper'

RSpec.describe TaxaController, type: :controller do
  let(:taxa_client) { instance_double(HTTPClients::ENATaxaClient) }

  before do
    # Inject the mocked client into the controller
    allow(taxa_client).to receive(:id_from_text) do |*|
      raise Faraday::ConnectionFailed unless defined?(id_from_text)

      id_from_text
    end
    allow(taxa_client).to receive(:name_from_id) do |*|
      raise Faraday::ConnectionFailed unless defined?(name_from_id)

      name_from_id
    end
    allow(controller).to receive(:client).and_return(taxa_client)
  end

  describe 'GET #index' do
    let(:term) { 'human' }

    before do
      get :index, params: { term: }
    end

    context 'with term parameter well defined' do
      let(:id_from_text) { 9606 }

      it 'returns 200 OK' do
        expect(response).to have_http_status(:ok)
      end

      it 'returns the lookup result' do
        expect(response.body).to eq(id_from_text.to_s)
      end
    end

    context 'with a term that does not exist' do
      let(:id_from_text) { nil }
      let(:term) { 'nonexistent_organism' }

      it 'returns 404 Not Found' do
        expect(response).to have_http_status(:not_found)
      end
    end

    context 'when Faraday raises a connection error' do
      it 'returns 502 Bad Gateway' do
        expect(response).to have_http_status(:bad_gateway)
      end
    end

    context 'without term param' do
      before do
        get :index
      end

      it 'returns 400 Bad Request' do
        expect(response).to have_http_status(:bad_request)
      end

      it 'provides a helpful error message' do
        expect(response.body).to eq('Missing required parameter: term')
      end
    end
  end

  describe 'GET #show' do
    let(:id) { '9606' }

    before do
      get :show, params: { id: }
    end

    context 'with a valid id' do
      let(:name_from_id) { 'homo sapiens' }

      it 'returns 200 OK' do
        expect(response).to have_http_status(:ok)
      end

      it 'returns the lookup result' do
        expect(response.body).to eq(name_from_id)
      end
    end

    context 'with an id that does not exist' do
      let(:name_from_id) { '' }

      it 'returns 404 Not Found' do
        expect(response).to have_http_status(:not_found)
      end

      it 'returns the lookup result' do
        expect(response.body).to eq(name_from_id)
      end
    end

    context 'when Faraday raises an error' do
      it 'returns 502 Bad Gateway' do
        expect(response).to have_http_status(:bad_gateway)
      end
    end
  end
end
