# frozen_string_literal: true

require 'rails_helper'
require './spec/models/schemas/shared_examples/validator'

RSpec.describe Schemas::JsonSchemaValidator do
  subject(:validator) { described_class.new(schema) }

  let(:schema) do
    Schemas::Schema.new(text: definition.to_json, type: :json_schema,
                        version: 1)
  end
  let(:definition) do
    {
      '$schema' => 'https://json-schema.org/draft/2020-12/schema',
      'type' => 'object',
      'required' => %w[request],
      'properties' => { 'request' => request_definition }
    }
  end
  let(:request_definition) do
    {
      'type' => 'object',
      'required' => %w[external_id],
      'properties' => {
        'external_id' => { 'type' => 'string', 'minLength' => 1 },
        'operation_id' => { 'type' => 'string', 'format' => 'uuid' }
      },
      'additionalProperties' => false
    }
  end
  let(:valid_payload) { { 'request' => { 'external_id' => 'request-1' } } }
  let(:invalid_payload) { { 'request' => { 'external_id' => 1 } } }

  def pointers(payload)
    validator.validate(payload).pluck(:pointer)
  end

  it_behaves_like 'a schema validator'

  it 'points to the invalid value' do
    expect(pointers(invalid_payload)).to eq(%w[/request/external_id])
  end

  it 'describes the problem' do
    expect(validator.validate(invalid_payload).first[:detail])
      .to eq('value at `/request/external_id` is not a string')
  end

  it 'returns an error for each invalid value' do
    payload = { 'request' => { 'external_id' => '', 'extra' => true } }
    expect(pointers(payload))
      .to contain_exactly('/request/external_id', '/request/extra')
  end

  it 'points to the object that lacks a required property' do
    expect(pointers({ 'request' => {} })).to eq(%w[/request])
  end

  it 'points to the root for a payload that is not an object' do
    expect(pointers([])).to eq([''])
  end

  it 'checks formats' do
    payload = { 'request' => { 'external_id' => 'request-1',
                               'operation_id' => 'not-a-uuid' } }
    expect(pointers(payload)).to eq(%w[/request/operation_id])
  end

  # prefixItems was added in draft 2020-12, so earlier drafts ignore it.
  context 'without a $schema keyword' do
    let(:definition) { { 'prefixItems' => [{ 'type' => 'string' }] } }

    it 'follows draft 2020-12' do
      expect(pointers([1])).to eq(%w[/0])
    end
  end

  context 'with a draft-07 $schema keyword' do
    let(:definition) do
      { '$schema' => 'http://json-schema.org/draft-07/schema#',
        'prefixItems' => [{ 'type' => 'string' }] }
    end

    it 'follows draft-07' do
      expect(pointers([1])).to eq([])
    end
  end

  context 'with a remote reference' do
    let(:definition) { { '$ref' => 'https://example.com/schema.json' } }

    it 'does not fetch it' do
      expect { validator.validate({}) }
        .to raise_error(JSONSchemer::UnknownRef)
    end
  end

  context 'with a schema that is not valid JSON Schema' do
    let(:definition) { { 'type' => 5 } }

    it 'raises an invalid schema error' do
      expect { validator }.to raise_error(
        described_class::InvalidSchema, 'The schema is not a valid JSON Schema.'
      )
    end
  end

  context 'with a schema that is not JSON' do
    let(:schema) do
      Schemas::Schema.new(text: '{"type":', type: :json_schema, version: 1)
    end

    it 'raises an invalid schema error' do
      expect { validator }.to raise_error(described_class::InvalidSchema,
                                          'The schema is not JSON.')
    end
  end
end
