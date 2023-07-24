# frozen_string_literal: true

require 'rails_helper'

RSpec.describe BulkSubmissionExcel::Configuration, bulk_submission_excel: true, type: :model do
  let(:configuration) { described_class.new }

  it 'is comparable' do
    expect(configuration).to eq(described_class.new)
  end

  it 'is able to add a new file' do
    configuration.add_file 'a_new_file'
    expect(configuration.files.length).to eq BulkSubmissionExcel::Configuration::FILES.length + 1
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
    let(:folder) { File.join('spec', 'data', 'bulk_submission_excel') }

    before do
      configuration.folder = folder
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
    end

    it 'load the conditional formattings' do
      expect(configuration.conditional_formattings).to eq(
        SequencescapeExcel::ConditionalFormattingDefaultList.new(
          configuration.load_file(folder, 'conditional_formattings')
        )
      )
    end

    it 'load the ranges' do
      expect(configuration.ranges).to eq(SequencescapeExcel::RangeList.new(configuration.load_file(folder, 'ranges')))
    end

    it 'freeze all of the configuration options' do
      expect(configuration.conditional_formattings).to be_frozen
      expect(configuration.ranges).to be_frozen
      expect(configuration.columns).to be_frozen
      expect(configuration.columns.all).to be_frozen
    end
  end
end
