# frozen_string_literal: true

require 'rails_helper'

RSpec.describe TaxaController, type: :controller do
  let(:taxa_client) { instance_double(HTTPClients::ENATaxaClient) }

  before do
    # Inject the mocked client into the controller
    allow(taxa_client).to receive(:taxon_from_text) do |*|
      raise Faraday::ConnectionFailed unless defined?(taxon_from_text)

      taxon_from_text
    end
    allow(taxa_client).to receive(:taxon_from_id) do |*|
      raise Faraday::ConnectionFailed unless defined?(taxon_from_id)

      taxon_from_id
    end
    allow(controller).to receive(:client).and_return(taxa_client)
  end

  describe 'GET #index' do
    let(:term) { 'human' }

    before do
      get :index, params: { term: }
    end

    context 'with term parameter well defined' do
      let(:taxon_from_text) { { 'commonName' => 'human', 'scientificName' => 'Homo sapiens', 'taxId' => '9606' } }

      it 'returns 200 OK' do
        expect(response).to have_http_status(:ok)
      end

      it 'returns the lookup result' do
        result = {
          'taxId' => '9606',
          'scientificName' => 'Homo sapiens',
          'commonName' => 'human'
        }
        expect(response.parsed_body).to eq(result)
      end
    end

    context 'with a term that does not exist' do
      let(:taxon_from_text) { nil }
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
    before do
      get :show, params: { id: }
    end

    context 'with a valid id' do
      let(:id) { '9606' }
      let(:taxon_from_id) { { 'commonName' => 'human', 'scientificName' => 'Homo sapiens', 'taxId' => '9606' } }

      it 'returns 200 OK' do
        expect(response).to have_http_status(:ok)
      end

      it 'returns the lookup result' do
        expect(response.parsed_body).to eq(taxon_from_id)
      end
    end

    context 'with an id that does not exist' do
      let(:id) { '0' }
      let(:taxon_from_id) { { taxId: nil } }

      it 'returns 404 Not Found' do
        expect(response).to have_http_status(:not_found)
      end
    end

    context 'when Faraday raises an error' do
      let(:id) { 'connection-dropped' }

      it 'returns 502 Bad Gateway' do
        expect(response).to have_http_status(:bad_gateway)
      end
    end
  end
end
