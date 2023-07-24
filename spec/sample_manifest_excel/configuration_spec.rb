# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SampleManifestExcel::Configuration, sample_manifest: true, sample_manifest_excel: true, type: :model do
  let(:configuration) { described_class.new }

  it 'is comparable' do
    expect(configuration).to eq(described_class.new)
  end

  it 'is able to add a new file' do
    configuration.add_file 'a_new_file'
    expect(configuration.files.length).to eq SampleManifestExcel::Configuration::FILES.length + 1
    expect(configuration.files).to include :a_new_file
    expect(configuration).to respond_to('a_new_file=')
  end

  it 'is able to set and get a tag group' do
    expect(configuration.tag_group).to be_nil
    configuration.tag_group = 'Main test group'
    expect(configuration.tag_group).to eq('Main test group')
  end

  describe 'without a folder' do
    it 'will not be loaded' do
      configuration.load!
      expect(configuration).not_to be_loaded
    end
  end

  describe 'with a valid folder' do
    let(:folder) { File.join('spec', 'data', 'sample_manifest_excel') }

    before do
      configuration.folder = folder
      configuration.tag_group = 'My Magic Tag Group'
      configuration.load!
    end

    it 'be loaded' do
      expect(configuration).to be_loaded
    end

    it 'will load the columns' do
      columns =
        SequencescapeExcel::ColumnList.new(
          configuration.load_file(folder, 'columns'),
          configuration.conditional_formattings
        )
      expect(configuration.columns.all).to eq(columns)
      configuration.manifest_types.each do |k, v|
        expect(configuration.columns.send(k)).to eq(columns.extract(v.columns))
        expect(configuration.columns.find(k)).to eq(columns.extract(v.columns))
        expect(configuration.columns.find(k.to_sym)).to eq(columns.extract(v.columns))
      end
    end

    it 'load the conditional formattings' do
      expect(configuration.conditional_formattings).to eq(
        SequencescapeExcel::ConditionalFormattingDefaultList.new(
          configuration.load_file(folder, 'conditional_formattings')
        )
      )
    end

    it 'load the manifest types' do
      expect(configuration.manifest_types).to eq(
        SampleManifestExcel::ManifestTypeList.new(configuration.load_file(folder, 'manifest_types'))
      )
    end

    it 'load the ranges' do
      expect(configuration.ranges).to eq(SequencescapeExcel::RangeList.new(configuration.load_file(folder, 'ranges')))
    end

    it 'freeze all of the configuration options' do
      expect(configuration.conditional_formattings).to be_frozen
      expect(configuration.manifest_types).to be_frozen
      expect(configuration.ranges).to be_frozen
      expect(configuration.columns).to be_frozen
      expect(configuration.columns.all).to be_frozen
      configuration.manifest_types.each { |k, _v| expect(configuration.columns.send(k)).to be_frozen }
    end

    it 'has a tag group' do
      expect(configuration.tag_group).to eq('My Magic Tag Group')
    end
  end
end
