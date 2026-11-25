# frozen_string_literal: true

require 'rails_helper'

RSpec.describe HTTPClients::ApiOperationCallbackClient do
  let(:client) { described_class.new }
  let(:url) { 'https://integration-hub.example.com/callbacks' }
  let(:payload) do
    { operation_type: 'reception_and_work_order', external_id: 'abc-123', status: 'work_order_completed' }
  end

  around do |example|
    original_url = configatron.integration_hub.operation_callback_url
    configatron.integration_hub.operation_callback_url = url
    example.run
  ensure
    configatron.integration_hub.operation_callback_url = original_url
  end

  it 'posts the payload as JSON with the operation ID as the idempotency key' do
    headers = { 'Content-Type' => 'application/json', 'Idempotency-Key' => 'abc-123' }
    stub = stub_request(:post, url).with(body: payload.to_json, headers: headers).to_return(status: 202)
    client.deliver(payload)
    expect(stub).to have_been_requested
  end

  it 'raises, without sending, when no callback URL is configured' do
    configatron.integration_hub.operation_callback_url = ''
    expect { client.deliver(payload) }.to raise_error(described_class::NotConfigured)
  end

  it 'raises when Integration Hub does not acknowledge' do
    stub_request(:post, url).to_return(status: 500)
    expect { client.deliver(payload) }.to raise_error(Faraday::ServerError)
  end

  it 'raises when the request times out' do
    stub_request(:post, url).to_timeout
    expect { client.deliver(payload) }.to raise_error(Faraday::ConnectionFailed)
  end
end
