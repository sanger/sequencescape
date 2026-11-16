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

  it 'says a numbered schema is not a WIP' do
    expect(source.fetch(schema_subject, version).wip).to be(false)
  end

  context 'with a WIP file' do
    before { write_schema('3.wip.json', '{"wip": true}') }

    it 'ignores it by default' do
      expect { source.fetch(schema_subject, 3) }
        .to raise_error(Schemas::Source::NotFound)
    end

    it 'leaves it out of the latest by default' do
      expect(source.fetch(schema_subject, :latest).version).to eq(2)
    end

    context 'when WIP files are read' do
      subject(:source) { described_class.new(root, wip: true) }

      it 'reads it as its version' do
        expect(source.fetch(schema_subject, 3))
          .to have_attributes(text: '{"wip": true}', version: 3, wip: true)
      end

      it 'counts it for the latest' do
        expect(source.fetch(schema_subject, :latest))
          .to have_attributes(version: 3, wip: true)
      end

      it 'still reads the numbered versions' do
        expect(source.fetch(schema_subject, version))
          .to have_attributes(text: text, wip: false)
      end

      it 'still ignores files not named by a version number' do
        %w[draft.json draft.wip.json 05.wip.json v6.wip.json]
          .each { |name| write_schema(name) }
        expect(source.fetch(schema_subject, :latest).version).to eq(3)
      end
    end
  end

  context 'with a WIP file for a version that has a file' do
    before { write_schema('2.wip.json') }

    it 'ignores the WIP file by default' do
      expect(source.fetch(schema_subject, 2).wip).to be(false)
    end

    context 'when WIP files are read' do
      subject(:source) { described_class.new(root, wip: true) }

      it 'raises a duplicate version error' do
        expect { source.fetch(schema_subject, version) }.to raise_error(
          described_class::DuplicateVersion,
          "#{schema_subject} version 2 has both 2.json and 2.wip.json in " \
          "#{root}"
        )
      end
    end
  end

  context 'with a WIP file of another type, when WIP files are read' do
    subject(:source) { described_class.new(root, wip: true) }

    before { write_schema('3.wip.avsc', '{"type": "record"}') }

    it 'raises an error for mixed types' do
      expect { source.fetch(schema_subject, :latest) }
        .to raise_error(described_class::MixedTypes)
    end
  end

  it 'raises not found for the latest of a subject it does not hold' do
    expect { source.fetch('other-subject', :latest) }
      .to raise_error(Schemas::Source::NotFound)
  end

  it 'reads from config/schemas by default' do
    expect(described_class.new.root).to eq(Rails.root.join('config/schemas'))
  end

  # The files kept in the repository, WIP files included, so a broken one
  # fails here rather than when a request is validated against it. A WIP
  # left beside the file it was renamed to fails as a duplicate version.
  context 'with the files in config/schemas' do
    Rails.root.glob('config/schemas/*/*.json').each do |path|
      it "holds a valid schema in #{path.relative_path_from(Rails.root)}" do
        # "2" for 2.json, and for 2.wip.json "2.wip", whose to_i is 2 too
        version = path.basename('.json').to_s.to_i
        schema = described_class.new(wip: true)
          .fetch(path.dirname.basename.to_s, version)
        expect { Schemas::JsonSchemaValidator.new(schema) }
          .not_to raise_error
      end
    end
  end
end
