# frozen_string_literal: true

require 'rails_helper'
require './spec/models/schemas/shared_examples/validator'

RSpec.describe Schemas::Validator do
  let(:schema) { Schemas::Schema.new(text: '{}', type: :json_schema) }

  it 'keeps the schema' do
    expect(described_class.new(schema).schema).to eq(schema)
  end

  it 'leaves validating to subclasses' do
    expect { described_class.new(schema).validate({}) }
      .to raise_error(NotImplementedError)
  end

  context 'with a subclass that checks a payload' do
    let(:validator) do
      Class.new(described_class) do
        def validate(payload)
          return [] if payload.key?('name')

          [{ pointer: '/name', detail: 'name is required.' }]
        end
      end.new(schema)
    end
    let(:valid_payload) { { 'name' => 'work order' } }
    let(:invalid_payload) { {} }

    it_behaves_like 'a schema validator'
  end
end
