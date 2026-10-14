# frozen_string_literal: true

require 'rails_helper'

describe 'Sapio Operations API' do
  let(:base_endpoint) { '/api/v2/sapio/operations' }
  let(:payload) { {} }
  let(:json) { response.parsed_body }

  def post_request
    headers = { 'CONTENT_TYPE' => 'application/json' }
    post base_endpoint, params: payload.to_json, headers: headers
  end

  context 'when the feature flag is disabled',
          :sapio_work_order_endpoint_disabled do
    before { post_request }

    it 'returns not found' do
      expect(response).to have_http_status(:not_found)
    end

    it 'returns a feature disabled error' do
      expect(json.dig('errors', 0, 'code')).to eq('FEATURE_DISABLED')
    end
  end

  context 'when the feature flag is enabled',
          :sapio_work_order_endpoint_enabled do
    before { post_request }

    it 'returns accepted' do
      expect(response).to have_http_status(:accepted)
    end
  end
end
