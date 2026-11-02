# frozen_string_literal: true

# Checks a Schemas::Source subclass. Needs `source`, the `schema_subject`
# and `version` of a schema it holds, its `latest_version`, and a
# `missing_version` of that schema that it doesn't hold.
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

  it 'returns the version asked for' do
    expect(schema.version).to eq(version)
  end

  it 'resolves the latest version' do
    expect(source.fetch(schema_subject, :latest).version)
      .to eq(latest_version)
  end

  it 'raises not found for a version it does not hold' do
    expect { source.fetch(schema_subject, missing_version) }
      .to raise_error(Schemas::Source::NotFound)
  end
end
