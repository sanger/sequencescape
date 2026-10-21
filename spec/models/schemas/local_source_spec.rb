# frozen_string_literal: true

require 'rails_helper'
require './spec/models/schemas/shared_examples/source'

RSpec.describe Schemas::LocalSource do
  subject(:source) { described_class.new(root) }

  let(:root) { Pathname(Dir.mktmpdir) }
  let(:schema_subject) { 'work-order' }
  let(:version) { 1 }
  let(:latest_version) { 2 }
  let(:missing_version) { 9 }
  # Spacing, key order and number formatting that parsing would lose
  let(:text) { %({"b": 1,\n  "a": 1.10}\n) }

  def write_schema(file_name, content)
    root.join(schema_subject).mkpath
    root.join(schema_subject, file_name).write(content)
  end

  before do
    write_schema('1.json', text)
    write_schema('2.json', '{}')
  end

  after { FileUtils.remove_entry(root) }

  it_behaves_like 'a schema source'

  it 'returns the file text exactly' do
    expect(source.fetch(schema_subject, version).text).to eq(text)
  end

  it 'reads a .json file as JSON Schema' do
    expect(source.fetch(schema_subject, version).type).to eq(:json_schema)
  end

  it 'reads an .avsc file as Avro' do
    write_schema('3.avsc', '{"type": "record"}')
    expect(source.fetch(schema_subject, 3).type).to eq(:avro)
  end

  it 'ignores files of other types' do
    write_schema('3.yml', 'type: object')
    expect { source.fetch(schema_subject, 3) }
      .to raise_error(Schemas::Source::NotFound)
  end

  it 'raises not found for a subject it does not hold' do
    expect { source.fetch('other-subject', version) }
      .to raise_error(Schemas::Source::NotFound)
  end

  it 'raises an error when a version has a file for each type' do
    write_schema('1.avsc', '{"type": "record"}')
    expect { source.fetch(schema_subject, version) }
      .to raise_error(RuntimeError, /More than one file/)
  end

  it 'compares versions as numbers for the latest' do
    write_schema('10.json', '{}')
    expect(source.fetch(schema_subject, :latest).version).to eq(10)
  end

  it 'includes every schema type for the latest' do
    write_schema('3.avsc', '{"type": "record"}')
    expect(source.fetch(schema_subject, :latest).type).to eq(:avro)
  end

  it 'ignores files not named by a version number for the latest' do
    %w[draft.json v5.json 05.json 6.yml].each do |name|
      write_schema(name, '{}')
    end
    expect(source.fetch(schema_subject, :latest).version).to eq(2)
  end

  it 'raises not found for the latest of a subject it does not hold' do
    expect { source.fetch('other-subject', :latest) }
      .to raise_error(Schemas::Source::NotFound)
  end

  it 'reads from config/schemas by default' do
    expect(described_class.new.root).to eq(Rails.root.join('config/schemas'))
  end
end
