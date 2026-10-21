# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Schemas::Provider do
  subject(:provider) { described_class.new(source) }

  let(:source) { instance_double(Schemas::Source, fetch: schema) }
  let(:schema) do
    Schemas::Schema.new(text: '{"type": "object"}', type: :json_schema,
                        version: 2)
  end
  let(:validator) do
    provider.validator_for(subject: 'work-order-schema', version: :latest)
  end

  it 'fetches the schema from the source' do
    validator
    expect(source).to have_received(:fetch).with('work-order-schema', :latest)
  end

  it 'gives a JSON Schema validator for a JSON Schema' do
    expect(validator).to be_a(Schemas::JsonSchemaValidator)
  end

  it 'gives the validator the fetched schema' do
    expect(validator.schema).to eq(schema)
  end

  it 'logs the subject and the version used' do
    allow(Rails.logger).to receive(:info)
    validator
    expect(Rails.logger).to have_received(:info)
      .with('Using schema work-order-schema version 2')
  end

  context 'with a schema type that has no validator' do
    let(:schema) do
      Schemas::Schema.new(text: '{"type": "record"}', type: :avro, version: 1)
    end

    it 'raises unsupported type' do
      expect { validator }.to raise_error(
        Schemas::Provider::UnsupportedType, 'No validator for avro schemas'
      )
    end
  end

  context 'when the source does not hold the schema' do
    before do
      allow(source).to receive(:fetch).and_raise(Schemas::Source::NotFound)
    end

    it 'raises not found' do
      expect { validator }.to raise_error(Schemas::Source::NotFound)
    end
  end

  context 'with a local source' do
    let(:root) { Pathname(Dir.mktmpdir) }
    let(:source) { Schemas::LocalSource.new(root) }

    before do
      root.join('json_schema/work-order-schema').mkpath
      root.join('json_schema/work-order-schema/1.json')
        .write('{"required": ["request"]}')
    end

    after { FileUtils.remove_entry(root) }

    it 'gives a validator that checks payloads against the file' do
      expect(validator.validate({}).pluck(:pointer)).to eq([''])
    end
  end
end
