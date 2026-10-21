# frozen_string_literal: true

require 'rails_helper'
require './spec/models/schemas/shared_examples/source'

RSpec.describe Schemas::LocalSource do
  subject(:source) { described_class.new(root) }

  let(:root) { Pathname(Dir.mktmpdir) }
  let(:schema_subject) { 'work-order' }
  let(:version) { 1 }
  let(:missing_version) { 2 }
  # Spacing, key order and number formatting that parsing would lose
  let(:text) { %({"b": 1,\n  "a": 1.10}\n) }

  def write_schema(file_name, content)
    root.join(schema_subject).mkpath
    root.join(schema_subject, file_name).write(content)
  end

  before { write_schema('1.json', text) }
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

  it 'reads from config/schemas by default' do
    expect(described_class.new.root).to eq(Rails.root.join('config/schemas'))
  end
end
