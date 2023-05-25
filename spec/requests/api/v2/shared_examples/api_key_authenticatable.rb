# frozen_string_literal: true

require 'rails_helper'

shared_examples_for 'ApiKeyAuthenticatable' do
  let(:client_headers) { { 'User-Agent' => 'Test Agent', 'Origin' => 'Test Origin' } }.freeze

  context 'without an API key' do
    it 'gets a success response' do
      api_get base_endpoint, headers: client_headers

      expect(response).to have_http_status(:success)
    end

    it 'logs the request with client details' do
      allow(Rails.logger).to receive(:info)

      api_get base_endpoint, headers: client_headers

      expect(Rails.logger).to have_received(:info).with(/Request made without an API key/)
      expect(Rails.logger).to have_received(:info).with(/:remote_ip=>"127.0.0.1"/)
      expect(Rails.logger).to have_received(:info).with(/:user_agent=>"Test Agent"/)
      expect(Rails.logger).to have_received(:info).with(/:origin=>"Test Origin"/)
      expect(Rails.logger).to have_received(:info).with(%r{:original_url=>"http://www.example.com#{base_endpoint}"})
      expect(Rails.logger).to have_received(:info).with(/:request_method=>"GET"/)
    end
  end

  context 'with an invalid API key' do
    let(:headers) { client_headers.merge!({ 'X-Sequencescape-Client-Id': 'invalid-key' }) }

    it 'gets an unauthorized response' do
      api_get base_endpoint, headers: headers

      expect(response).to have_http_status(:unauthorized)
    end

    it 'logs the request with client details' do
      allow(Rails.logger).to receive(:info)

      api_get base_endpoint, headers: headers

      expect(Rails.logger).to have_received(:info).with(/Request made with invalid API key/)
      expect(Rails.logger).to have_received(:info).with(/:remote_ip=>"127.0.0.1"/)
      expect(Rails.logger).to have_received(:info).with(/:user_agent=>"Test Agent"/)
      expect(Rails.logger).to have_received(:info).with(/:origin=>"Test Origin"/)
      expect(Rails.logger).to have_received(:info).with(%r{:original_url=>"http://www.example.com#{base_endpoint}"})
      expect(Rails.logger).to have_received(:info).with(/:request_method=>"GET"/)
      expect(Rails.logger).to have_received(:info).with(/:api_key=>"invalid-key"/)
    end
  end

  context 'with a valid application API key' do
    let(:api_application) { create(:api_application) }
    let(:headers) { client_headers.merge!({ 'X-Sequencescape-Client-Id': api_application.key }) }

    it 'gets a success response' do
      api_get base_endpoint, headers: headers

      expect(response).to have_http_status(:success)
    end
  end
end
