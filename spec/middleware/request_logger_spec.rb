# frozen_string_literal: true

require 'rails_helper'

RSpec.describe RequestLogger do
  let(:request_logger_regex) do
    %r{
          \[RequestLogger\]
          .*
          "method":"GET",
          .*
          "path":"/samples/1234\?foo=bar",
          .*
          "status_code":#{status_code},
          .*
          "client_ip":"127.0.0.1",
          .*
          "request_id":"test-request-id",
          .*
          "@timestamp":"2026-02-12T12:10:50.284\+00:00"
        }x
  end

  let(:env) do
    Rack::MockRequest.env_for(
      '/samples/1234?foo=bar',
      'REQUEST_METHOD' => 'GET',
      'REMOTE_ADDR' => '127.0.0.1',
      'action_dispatch.request_id' => 'test-request-id',
      'action_dispatch.request.parameters' => {},
      'action_dispatch.request.formats' => [Mime[:html]]
    )
  end

  let(:status_code) { 200 }
  let(:app) { ->(_env) { [status_code, { 'Content-Type' => 'text/html' }, 'Response Body'] } }

  before do
    allow(Time.zone).to receive(:now).and_return(Time.parse('2026-02-12T12:10:50.284+00:00'))
    allow(Rails.logger).to receive(:debug)
    allow(Rails.logger).to receive(:info)
  end

  shared_examples 'logs request with' do |log_level|
    let(:middleware) { described_class.new(app, log_level:) }

    it 'calls the app and returns the response' do
      expect(middleware.call(env)).to eq([status_code, { 'Content-Type' => 'text/html' }, 'Response Body'])
    end

    it 'logs the request with correct structure' do
      middleware.call(env)
      expect(Rails.logger).to have_received(log_level).with(a_string_matching(request_logger_regex))
    end
  end

  context 'when response is 200 OK' do
    let(:status_code) { 200 }

    it_behaves_like 'logs request with', :info
  end

  context 'when response is 404 Not Found' do
    let(:status_code) { 404 }

    it_behaves_like 'logs request with', :info
  end

  context 'when response is 500 Internal Server Error' do
    let(:status_code) { 500 }

    it_behaves_like 'logs request with',  :info
  end

  context 'when log level is set to :debug' do
    it_behaves_like 'logs request with',  :debug
  end
end
