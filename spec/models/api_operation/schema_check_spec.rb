# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ApiOperation::SchemaCheck do
  subject(:check) { described_class.new(payload) }

  let(:payload) { { 'request' => {} } }
  let(:found) { [] }
  let(:schema) do
    Schemas::Schema.new(text: '{}', type: :json_schema, version: 7)
  end
  let(:validator) do
    instance_double(Schemas::JsonSchemaValidator, validate: found,
                                                  schema: schema)
  end
  let(:provider) do
    instance_double(Schemas::Provider, validator_for: validator)
  end

  before do
    allow(Schemas::Provider).to receive(:configured).and_return(provider)
  end

  def problem(number)
    { pointer: "/labware/#{number}", detail: "problem #{number}" }
  end

  it 'uses the schema the test settings name' do
    check.valid?
    expect(provider).to have_received(:validator_for)
      .with(subject: 'work-order-schema', version: :latest)
  end

  it 'checks the payload' do
    check.valid?
    expect(validator).to have_received(:validate).with(payload)
  end

  it 'names the schema and version used' do
    expect(check.schema_meta).to eq(schema: 'work-order-schema', version: 7)
  end

  context 'with other schema settings' do
    let(:schema) do
      Schemas::Schema.new(text: '{}', type: :json_schema, version: 3)
    end

    before do
      allow(Rails.application.config).to receive_messages(
        sapio_schema_subject: 'other-subject', sapio_schema_version: '3'
      )
    end

    it 'uses the schema those settings name' do
      check.valid?
      expect(provider).to have_received(:validator_for)
        .with(subject: 'other-subject', version: 3)
    end

    it 'names that schema and version' do
      expect(check.schema_meta).to eq(schema: 'other-subject', version: 3)
    end
  end

  context 'without problems' do
    it 'is valid' do
      expect(check).to be_valid
    end

    it 'has a total of none' do
      expect(check.total).to eq(0)
    end
  end

  context 'with problems' do
    let(:found) { [problem(0), problem(1)] }

    it 'is not valid' do
      expect(check).not_to be_valid
    end

    it 'keeps the problems' do
      expect(check.problems).to eq(found)
    end

    it 'counts the problems' do
      expect(check.total).to eq(2)
    end
  end

  context 'with more problems than are kept' do
    let(:found) { Array.new(3) { |number| problem(number) } }

    before { stub_const("#{described_class}::MAX_PROBLEMS", 2) }

    it 'keeps the first problems' do
      expect(check.problems).to eq(found.first(2))
    end

    it 'counts all the problems' do
      expect(check.total).to eq(3)
    end
  end

  it 'validates the payload only once' do
    check.valid?
    check.problems
    check.total
    expect(validator).to have_received(:validate).once
  end
end
