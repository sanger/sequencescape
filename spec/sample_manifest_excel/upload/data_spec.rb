# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SampleManifestExcel::Upload::Data, :sample_manifest, :sample_manifest_excel, type: :model do
  before(:all) do
    SampleManifestExcel.configure do |config|
      config.folder = File.join('spec', 'data', 'sample_manifest_excel')
      config.load!
    end
  end

  let(:test_file_name) { 'test_file.xlsx' }
  let(:test_file) { Rack::Test::UploadedFile.new(Rails.root.join(test_file_name), '') }
  let(:columns) { SampleManifestExcel.configuration.columns.tube_library_with_tag_sequences.dup }
  let!(:download) { build(:test_download_tubes, columns:) }

  before { download.save(test_file_name) }

  after(:all) { SampleManifestExcel.reset! }

  after { File.delete(test_file_name) if File.exist?(test_file_name) }

  it 'is not valid without a filename' do
    expect(described_class.new(nil)).not_to be_valid
  end

  it '#header_row returns the header columns' do
    data = described_class.new(test_file)
    spreadsheet = Roo::Spreadsheet.open(test_file).sheet(0)
    expect(data.header_row).to eq(spreadsheet.row(9))
  end

  it '#column returns a column of data' do
    data = described_class.new(test_file)
    spreadsheet = Roo::Spreadsheet.open(test_file).sheet(0)
    expect(data.column(spreadsheet.last_row - 1)).to eq(spreadsheet.column(spreadsheet.last_row - 1).drop(9))
  end

  it '#cell returns a cell of data' do
    data = described_class.new(test_file)
    spreadsheet = Roo::Spreadsheet.open(test_file).sheet(0)
    #Validate that the value of the cell at the last row and last column is not nil and matches the expected value
    # huMFRe_code is the last column in the test file
    expect(data.cell(spreadsheet.last_row - 10, spreadsheet.last_column)).not_to be_nil
    expect(data.cell(spreadsheet.last_row - 10, spreadsheet.last_column)).to eq(
      spreadsheet.cell(spreadsheet.last_row, spreadsheet.last_column)
    )
  end

  context 'when the file is invalid' do
    let(:test_file) { File.open('./tmp/nonsense.xlsx', 'w+') { |f| f << 'INVALID FILE CONTENT' } }

    it 'is invalid' do
      expect(described_class.new(test_file)).not_to be_valid
    end
  end
end
