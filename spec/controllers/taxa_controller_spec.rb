# frozen_string_literal: true

require 'rails_helper'

RSpec.describe TaxaController, type: :controller do
  let(:remote_status) { 200 }
  let(:remote_body) { 'taxon lookup result' }

  before do
    # we haven't got a nice way to inject the Faraday client, so we'll monkeypatch it instead
    response_dbl = instance_double(Faraday::Response)
    allow(response_dbl).to receive_messages(status: remote_status, body: remote_body)
    allow_any_instance_of(Faraday::Connection).to receive(:get).and_return(response_dbl) # rubocop:disable RSpec/AnyInstance
  end

  around do |example|
    configatron_tmp = configatron.dup
    configatron.disable_web_proxy = true
    configatron.proxy = nil

    example.run

    configatron.replace(configatron_tmp)
  end

  describe 'GET #index' do
    context 'with term param' do
      let(:remote_body) { 'homo sapiens' }
      let(:term) { 'human' }

      before do
        get :index, params: { term: }
      end

      it 'returns 200 OK' do
        puts response.inspect

        expect(response).to have_http_status(:ok)
      end

      it 'returns the lookup result' do
        expect(response.body).to eq(remote_body)
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

    context 'when Faraday raises an error' do
      before do
        allow_any_instance_of(Faraday::Connection).to receive(:get).and_raise(Faraday::Error) # rubocop:disable RSpec/AnyInstance

        get :index, params: { term: 'foo' }
      end

      it 'returns 502 Bad Gateway' do
        expect(response).to have_http_status(:bad_gateway)
      end
    end
  end

  describe 'GET #show' do
    let(:id) { '9606' }

    before do
      get :show, params: { id: }
    end

    it 'returns 200 OK' do
      expect(response).to have_http_status(:ok)
    end

    it 'returns the lookup result' do
      expect(response.body).to eq(remote_body)
    end

    context 'when Faraday raises an error' do
      before do
        allow_any_instance_of(Faraday::Connection).to receive(:get).and_raise(Faraday::Error) # rubocop:disable RSpec/AnyInstance

        get :show, params: { id: }
      end

      it 'returns 502 Bad Gateway' do
        expect(response).to have_http_status(:bad_gateway)
      end
    end
  end
end
