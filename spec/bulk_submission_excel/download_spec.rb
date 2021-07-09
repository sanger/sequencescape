# frozen_string_literal: true

require 'rails_helper'

RSpec.describe BulkSubmissionExcel::Download, type: :model, bulk_submission_excel: true do
  attr_reader :download, :spreadsheet

  let(:test_file) { 'test.xlsx' }

  let(:configuration) do
    BulkSubmissionExcel::Configuration.new do |config|
      config.folder = File.join('spec', 'data', 'bulk_submission_excel')
      config.load!
    end
  end

  let(:download) do
    described_class.new(
      assets: assets,
      column_list: columns,
      range_list: ranges,
      defaults: {
        user_login: 'abc123',
        template_name: submission_template.name
      }
    )
  end

  # Defaults
  let(:columns) { configuration.columns.all.dup }
  let(:ranges) { configuration.ranges.dup }
  let(:assets) { create(:plate_with_untagged_wells).wells }
  let(:submission_template) { create :libray_and_sequencing_template }

  after { File.delete(test_file) if File.exist?(test_file) }

  context 'without columns' do
    let(:columns) { nil }

    it 'is not valid' do
      expect(download).not_to be_valid
    end
  end

  context 'without ranges' do
    let(:ranges) { nil }

    it 'is not valid' do
      expect(download).not_to be_valid
    end
  end

  context 'with all fields' do
    it 'is valid' do
      expect(download).to be_valid
    end
  end

  context 'Generated File' do
    before do
      create(:library_type, name: 'Other')
      create(:library_type, name: 'Again')
      download.save(test_file)
    end

    let(:spreadsheet) { Roo::Spreadsheet.open(test_file) }

    it 'creates an excel file' do
      expect(File).to be_file(test_file)
    end

    it 'creates the two different types of worksheet' do
      expect(spreadsheet.sheets.first).to eq('Submission Form')
      expect(spreadsheet.sheets.last).to eq('Ranges')
    end

    it 'have the correct number of columns' do
      expect(download.column_list.count).to eq(configuration.columns.all.count)
    end
  end
end
