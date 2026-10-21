# frozen_string_literal: true

# Checks a Schemas::Source subclass. Needs `source`, and the `schema_subject`
# and `version` of a schema it holds.
shared_examples 'a schema source' do
  let(:schema) { source.fetch(schema_subject, version) }

  it 'returns a schema' do
    expect(schema).to be_a(Schemas::Schema)
  end

  it 'returns the schema text' do
    expect(schema.text).to be_a(String)
  end

  it 'returns a known schema type' do
    expect(Schemas::Schema::TYPES).to include(schema.type)
  end
end
