# frozen_string_literal: true

require 'rails_helper'

shared_examples_for 'ApiKeyAuthenticatable' do
  let(:client_headers) { { 'User-Agent' => 'Test Agent', 'Origin' => 'Test Origin' } }.freeze
  let(:permissive_route) do
    Rails.application.routes.recognize_path(base_endpoint, method: :get).fetch(:permissive, []).include?(:get)
  end

  context 'without an API key' do
    context 'when feature flag is disabled' do
      before { Flipper.disable :y25_442_make_api_key_mandatory }

      it 'gets a success response' do
        api_get base_endpoint, headers: client_headers

        expect(response).to have_http_status(:success)
      end
    end

    context 'when feature flag is enabled' do
      before { Flipper.enable :y25_442_make_api_key_mandatory }

      it 'gets an unauthorized response' do
        api_get base_endpoint, headers: client_headers

        # Permissive routes are successful without API keys
        if permissive_route
          expect(response).to have_http_status(:success)
        else
          expect(response).to have_http_status(:unauthorized)
        end
      end
    end

    it 'logs the request with client details' do
      allow(Rails.logger).to receive(:info)

      api_get base_endpoint, headers: client_headers

      # Permissive routes don't log details
      unless permissive_route
        expect(Rails.logger).to have_received(:info).with(/Request made without an API key/)
        expect(Rails.logger).to have_received(:info).with(/remote_ip: "127.0.0.1"/)
        expect(Rails.logger).to have_received(:info).with(/user_agent: "Test Agent"/)
        expect(Rails.logger).to have_received(:info).with(/origin: "Test Origin"/)
        expect(Rails.logger).to have_received(:info).with(%r{original_url: "http://www.example.com#{base_endpoint}"})
        expect(Rails.logger).to have_received(:info).with(/request_method: "GET"/)
      end
    end
  end

  context 'with an invalid API key' do
    let(:headers) { client_headers.merge!({ 'X-Sequencescape-Client-Id': 'invalid-key' }) }

    it 'gets an unauthorized response' do
      api_get(base_endpoint, headers:)

      # Permissive routes are successful with invalid API keys
      if permissive_route
        expect(response).to have_http_status(:success)
      else
        expect(response).to have_http_status(:unauthorized)
      end
    end

    it 'logs the request with client details' do
      allow(Rails.logger).to receive(:info)

      api_get(base_endpoint, headers:)

      # Permissive routes don't log details
      unless permissive_route
        expect(Rails.logger).to have_received(:info).with(/Request made with invalid API key/)
        expect(Rails.logger).to have_received(:info).with(/remote_ip: "127.0.0.1"/)
        expect(Rails.logger).to have_received(:info).with(/user_agent: "Test Agent"/)
        expect(Rails.logger).to have_received(:info).with(/origin: "Test Origin"/)
        expect(Rails.logger).to have_received(:info).with(%r{original_url: "http://www.example.com#{base_endpoint}"})
        expect(Rails.logger).to have_received(:info).with(/request_method: "GET"/)
        expect(Rails.logger).to have_received(:info).with(/api_key: "invalid-key"/)
      end
    end
  end

  context 'with a valid application API key' do
    let(:api_application) { create(:api_application) }
    let(:headers) { client_headers.merge!({ 'X-Sequencescape-Client-Id': api_application.key }) }

    it 'gets a success response' do
      api_get(base_endpoint, headers:)

      expect(response).to have_http_status(:success)
    end
  end
end
