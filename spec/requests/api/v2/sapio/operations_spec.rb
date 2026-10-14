# frozen_string_literal: true

require 'rails_helper'

describe 'Sapio Operations API' do
  let(:base_endpoint) { '/api/v2/sapio/operations' }
  let(:integration_hub_app) do
    create(:api_application, name: ApiApplication::INTEGRATION_HUB_NAME)
  end
  let(:other_app) { create(:api_application) }
  let(:payload) { {} }
  let(:json) { response.parsed_body }

  def post_request(api_key: nil)
    headers = { 'CONTENT_TYPE' => 'application/json' }
    headers['X-Sequencescape-Client-Id'] = api_key if api_key
    post base_endpoint, params: payload.to_json, headers: headers
  end

  context 'when the feature flag is disabled',
          :sapio_work_order_endpoint_disabled do
    before { post_request(api_key: integration_hub_app.key) }

    it 'returns not found' do
      expect(response).to have_http_status(:not_found)
    end

    it 'returns a feature disabled error' do
      expect(json.dig('errors', 0, 'code')).to eq('FEATURE_DISABLED')
    end
  end

  context 'when the feature flag is enabled',
          :sapio_work_order_endpoint_enabled do
    context 'without an API key when API keys are mandatory' do
      before do
        Flipper.enable(:y25_442_make_api_key_mandatory)
        post_request
      end

      it 'returns unauthorized' do
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'without an API key when API keys are optional' do
      before do
        Flipper.disable(:y25_442_make_api_key_mandatory)
        post_request
      end

      it 'returns forbidden' do
        expect(response).to have_http_status(:forbidden)
      end
    end

    context 'with an unknown API key' do
      before { post_request(api_key: 'unknown') }

      it 'returns unauthorized' do
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'with another application API key' do
      before { post_request(api_key: other_app.key) }

      it 'returns forbidden' do
        expect(response).to have_http_status(:forbidden)
      end

      it 'returns an Integration Hub API key required error' do
        expect(json.dig('errors', 0, 'detail'))
          .to eq('Integration Hub API key required.')
      end
    end

    context 'with the Integration Hub API key' do
      before { post_request(api_key: integration_hub_app.key) }

      it 'returns accepted' do
        expect(response).to have_http_status(:accepted)
      end
    end
  end
end
