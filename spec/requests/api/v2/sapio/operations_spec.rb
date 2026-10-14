# frozen_string_literal: true

require 'rails_helper'

describe 'Sapio Operations API' do
  let(:base_endpoint) { '/api/v2/sapio/operations' }
  let(:integration_hub_app) do
    create(:api_application, name: ApiApplication::INTEGRATION_HUB_NAME)
  end
  let(:other_app) { create(:api_application) }
  # The smallest payload with the expected top level.
  let(:valid_payload) do
    { request: { external_id: 'request-1' }, labware: [], work_order: {} }
  end
  let(:body) { valid_payload.to_json }
  let(:json) { response.parsed_body }

  def post_request(api_key: nil)
    headers = { 'CONTENT_TYPE' => 'application/json' }
    headers['X-Sequencescape-Client-Id'] = api_key if api_key
    post base_endpoint, params: body, headers: headers
  end

  context 'when the feature flag is disabled',
          :sapio_operations_endpoint_disabled do
    before { post_request(api_key: integration_hub_app.key) }

    it 'returns not found' do
      expect(response).to have_http_status(:not_found)
    end

    it 'returns a feature disabled error' do
      expect(json.dig('errors', 0, 'code')).to eq('FEATURE_DISABLED')
    end
  end

  context 'when the feature flag is enabled',
          :sapio_operations_endpoint_enabled do
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

    context 'when Rails logs the request parameters' do
      let(:logged) { [] }

      before do
        allow(Rails.logger).to receive(:info)
          .and_wrap_original do |original, *args, &block|
            logged << args.first.to_s if args.first.to_s.include?('Parameters:')
            original.call(*args, &block)
          end
        post_request(api_key: integration_hub_app.key)
      end

      it 'logs the payload as filtered' do
        expect(logged.join).to include('[FILTERED]')
      end

      it 'does not log the payload values' do
        expect(logged.join).not_to include('request-1')
      end

      it 'does not log a wrapped copy of the payload' do
        expect(logged.join).not_to include('operation')
      end
    end

    context 'with the Integration Hub API key' do
      before { post_request(api_key: integration_hub_app.key) }

      it 'returns accepted' do
        expect(response).to have_http_status(:accepted)
      end

      context 'with invalid JSON' do
        let(:body) { '{"request": ' }

        it 'returns bad request' do
          expect(response).to have_http_status(:bad_request)
        end

        it 'returns an invalid JSON error' do
          expect(json.dig('errors', 0, 'code')).to eq('INVALID_JSON')
        end
      end

      context 'with an empty body' do
        let(:body) { '' }

        it 'returns bad request' do
          expect(response).to have_http_status(:bad_request)
        end
      end

      # Each case changes the valid payload and names the expected pointer.
      {
        'a body that is not an object' => [->(_) { [] }, ''],
        'no request section' =>
          [->(p) { p.except(:request) }, '/request/external_id'],
        'a request section that is not an object' =>
          [->(p) { p.merge(request: 'request-1') }, '/request/external_id'],
        'an empty external ID' =>
          [->(p) { p.merge(request: { external_id: '' }) },
           '/request/external_id'],
        'an external ID that is not a string' =>
          [->(p) { p.merge(request: { external_id: 1 }) },
           '/request/external_id'],
        'no labware section' => [->(p) { p.except(:labware) }, '/labware'],
        'a labware section that is not an array' =>
          [->(p) { p.merge(labware: {}) }, '/labware'],
        'no work order section' =>
          [->(p) { p.except(:work_order) }, '/work_order'],
        'a work order section that is not an object' =>
          [->(p) { p.merge(work_order: []) }, '/work_order']
      }.each do |description, (change, pointer)|
        context "with #{description}" do
          let(:body) { change.call(valid_payload).to_json }

          it 'returns unprocessable content' do
            expect(response).to have_http_status(:unprocessable_content)
          end

          it 'returns an invalid structure error' do
            expect(json.dig('errors', 0, 'code')).to eq('INVALID_STRUCTURE')
          end

          it 'points to the problem' do
            expect(json.dig('errors', 0, 'source', 'pointer')).to eq(pointer)
          end
        end
      end

      context 'with an empty object' do
        let(:body) { {}.to_json }

        it 'returns an error for each missing part' do
          pointers =
            json['errors'].map { |error| error.dig('source', 'pointer') }
          expect(pointers).to eq(%w[/request/external_id /labware /work_order])
        end
      end
    end
  end
end
