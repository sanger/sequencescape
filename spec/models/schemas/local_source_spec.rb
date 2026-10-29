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

  def write_schema(file_name, content = '{}', subject = schema_subject)
    root.join(subject).mkpath
    root.join(subject, file_name).write(content)
  end

  before do
    write_schema('1.json', text)
    write_schema('2.json')
  end

  after { FileUtils.remove_entry(root) }

  it_behaves_like 'a schema source'

  it 'returns the file text exactly' do
    expect(source.fetch(schema_subject, version).text).to eq(text)
  end

  it 'reads .json files as JSON Schema' do
    expect(source.fetch(schema_subject, version).type).to eq(:json_schema)
  end

  it 'reads .avsc files as Avro' do
    write_schema('1.avsc', '{"type": "record"}', 'avro-subject')
    expect(source.fetch('avro-subject', 1).type).to eq(:avro)
  end

  it 'ignores files with other extensions' do
    %w[3.yml 3.txt].each { |name| write_schema(name) }
    expect { source.fetch(schema_subject, 3) }
      .to raise_error(Schemas::Source::NotFound)
  end

  it 'ignores files in folders inside the subject folder' do
    write_schema('3.json', '{}', "#{schema_subject}/drafts")
    expect { source.fetch(schema_subject, 3) }
      .to raise_error(Schemas::Source::NotFound)
  end

  it 'raises not found for a subject it does not hold' do
    expect { source.fetch('other-subject', version) }
      .to raise_error(Schemas::Source::NotFound)
  end

  # A schema registry keeps all versions of a subject to one type
  context 'with a subject with versions of more than one type' do
    before { write_schema('3.avsc', '{"type": "record"}') }

    [1, 3, :latest].each do |asked|
      it "raises an error for version #{asked.inspect}" do
        expect { source.fetch(schema_subject, asked) }
          .to raise_error(described_class::MixedTypes,
                          /more than one schema type/)
      end
    end
  end

  it 'compares versions as numbers for the latest' do
    write_schema('10.json')
    expect(source.fetch(schema_subject, :latest).version).to eq(10)
  end

  it 'ignores folders named like version files for the latest' do
    root.join(schema_subject, '5.json').mkpath
    expect(source.fetch(schema_subject, :latest).version).to eq(2)
  end

  it 'ignores files not named by a version number for the type' do
    write_schema('draft.avsc', '{"type": "record"}')
    expect(source.fetch(schema_subject, :latest).type).to eq(:json_schema)
  end

  it 'ignores files not named by a version number for the latest' do
    %w[draft.json v5.json 05.json 7.yml].each { |name| write_schema(name) }
    expect(source.fetch(schema_subject, :latest).version).to eq(2)
  end

  it 'raises not found for the latest of a subject it does not hold' do
    expect { source.fetch('other-subject', :latest) }
      .to raise_error(Schemas::Source::NotFound)
  end

  it 'reads from config/schemas by default' do
    expect(described_class.new.root).to eq(Rails.root.join('config/schemas'))
  end

  # The files kept in the repository, so a broken one fails here rather
  # than when a request is validated against it
  context 'with the files in config/schemas' do
    Rails.root.glob('config/schemas/*/*.json').each do |path|
      it "holds a valid schema in #{path.relative_path_from(Rails.root)}" do
        schema = described_class.new.fetch(path.dirname.basename.to_s,
                                           path.basename('.json').to_s.to_i)
        expect { Schemas::JsonSchemaValidator.new(schema) }
          .not_to raise_error
      end
    end
  end
end
