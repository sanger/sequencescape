# frozen_string_literal: true

require 'rails_helper'
require 'webmock/rspec'

RSpec.describe HTTPClients::SchemaRegistryClient do
  let(:client) { described_class.new('http://test-registry') }
  let(:answer) do
    { 'subject' => 'work-order-schema', 'version' => 3, 'id' => 1,
      'schemaType' => 'JSON', 'schema' => '{"type": "object"}' }
  end

  def stub_registry(path)
    stub_request(:get, "http://test-registry/subjects/#{path}")
      .with(headers: { 'Accept' => described_class::MEDIA_TYPE })
  end

  def registry_answer(body, status: 200)
    { status: status, body: body.to_json,
      headers: { 'Content-Type' => described_class::MEDIA_TYPE } }
  end

  describe '#conn' do
    it 'uses the registry URL' do
      expect(client.conn.url_prefix.to_s).to eq('http://test-registry/')
    end

    it 'includes the default headers' do
      expect(client.conn.headers['User-Agent'])
        .to eq('Sequencescape Schema Registry Client')
    end

    it 'waits only briefly for a connection' do
      expect(client.conn.options.open_timeout)
        .to eq(described_class::OPEN_TIMEOUT)
    end

    it 'waits only briefly for a response' do
      expect(client.conn.options.timeout).to eq(described_class::TIMEOUT)
    end
  end

  describe '#schema_version' do
    it 'returns the registry answer for a version' do
      stub_registry('work-order-schema/versions/3')
        .to_return(registry_answer(answer))
      expect(client.schema_version('work-order-schema', 3)).to eq(answer)
    end

    it 'asks for the latest version' do
      stub_registry('work-order-schema/versions/latest')
        .to_return(registry_answer(answer))
      expect(client.schema_version('work-order-schema', :latest)).to eq(answer)
    end

    it 'escapes the subject' do
      stub_registry('a%20subject/versions/1').to_return(registry_answer(answer))
      expect(client.schema_version('a subject', 1)).to eq(answer)
    end

    it 'raises not found for a version the registry does not hold' do
      stub_registry('work-order-schema/versions/9')
        .to_return(registry_answer({ 'error_code' => 40_402 }, status: 404))
      expect { client.schema_version('work-order-schema', 9) }
        .to raise_error(Faraday::ResourceNotFound)
    end

    it 'raises a server error for an error answer' do
      stub_registry('work-order-schema/versions/3')
        .to_return(registry_answer({}, status: 500))
      expect { client.schema_version('work-order-schema', 3) }
        .to raise_error(Faraday::ServerError)
    end

    it 'raises an error when the registry takes too long' do
      stub_registry('work-order-schema/versions/3').to_timeout
      expect { client.schema_version('work-order-schema', 3) }
        .to raise_error(Faraday::Error)
    end
  end
end
