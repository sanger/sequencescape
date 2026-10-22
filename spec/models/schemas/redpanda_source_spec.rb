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

  # The test environment's cache keeps nothing, so these use a memory store.
  context 'with a cache' do
    let(:cache) { ActiveSupport::Cache::MemoryStore.new }
    let(:other_source) { described_class.new('http://other-registry') }

    before { allow(Rails).to receive(:cache).and_return(cache) }

    def fetch_twice(asked)
      2.times do
        suppress(Schemas::Source::NotFound) do
          source.fetch(schema_subject, asked)
        end
      end
    end

    it 'asks the registry for a version only once' do
      fetch_twice(version)
      expect(a_request(:get, %r{/versions/1\z})).to have_been_made.once
    end

    it 'asks the registry for the latest version every time' do
      fetch_twice(:latest)
      expect(a_request(:get, %r{/versions/latest\z})).to have_been_made.twice
    end

    it 'does not keep a version the registry does not hold' do
      fetch_twice(missing_version)
      expect(a_request(:get, %r{/versions/9\z})).to have_been_made.twice
    end

    it 'gives a kept version when the registry is down' do
      source.fetch(schema_subject, version)
      stub_request(:get, %r{/versions/1\z}).to_timeout
      expect(source.fetch(schema_subject, version).text).to eq(text)
    end

    it 'keeps the versions of different registries apart' do
      source.fetch(schema_subject, version)
      stub_request(:get, %r{other-registry/}).to_return(status: 404)
      expect { other_source.fetch(schema_subject, version) }
        .to raise_error(Schemas::Source::NotFound)
    end
  end
end
