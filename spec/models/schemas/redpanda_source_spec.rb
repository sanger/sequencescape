# frozen_string_literal: true

require 'rails_helper'
require 'webmock/rspec'
require './spec/models/schemas/shared_examples/source'

RSpec.describe Schemas::RedpandaSource do
  subject(:source) { described_class.new('http://test-registry') }

  let(:schema_subject) { 'work-order-schema' }
  let(:version) { 1 }
  let(:latest_version) { 2 }
  let(:missing_version) { 9 }
  let(:text) { %({"b": 1,\n  "a": 1.10}\n) }

  def stub_version(version_path, answer = nil, status: 200)
    stub_request(:get, 'http://test-registry/subjects/work-order-schema/' \
                       "versions/#{version_path}")
      .to_return(status: status, body: answer.to_json,
                 headers: { 'Content-Type' =>
                            HTTPClients::SchemaRegistryClient::MEDIA_TYPE })
  end

  def answer(version, schema_type = 'JSON')
    { 'subject' => 'work-order-schema', 'version' => version, 'id' => 7,
      'schemaType' => schema_type, 'schema' => text }.compact
  end

  before do
    stub_version(1, answer(1))
    stub_version('latest', answer(2))
    stub_version(9, { 'error_code' => 40_402 }, status: 404)
  end

  it_behaves_like 'a schema source'

  it 'returns the schema text from the registry exactly' do
    expect(source.fetch(schema_subject, version).text).to eq(text)
  end

  it 'reads a JSON schema type as JSON Schema' do
    expect(source.fetch(schema_subject, version).type).to eq(:json_schema)
  end

  {
    'no schema type' => nil,
    'the AVRO schema type' => 'AVRO'
  }.each do |description, schema_type|
    it "reads #{description} as Avro" do
      stub_version(3, answer(3, schema_type))
      expect(source.fetch(schema_subject, 3).type).to eq(:avro)
    end
  end

  it 'raises unsupported type for another schema type' do
    stub_version(3, answer(3, 'PROTOBUF'))
    expect { source.fetch(schema_subject, 3) }.to raise_error(
      Schemas::Provider::UnsupportedType, 'No validator for PROTOBUF schemas'
    )
  end

  it 'raises unavailable for an error answer' do
    stub_version(3, {}, status: 500)
    expect { source.fetch(schema_subject, 3) }
      .to raise_error(Schemas::Source::Unavailable)
  end

  it 'raises unavailable when the registry takes too long' do
    stub_request(:get, %r{/versions/3\z}).to_timeout
    expect { source.fetch(schema_subject, 3) }
      .to raise_error(Schemas::Source::Unavailable)
  end
end
