require 'rails_helper'

RSpec.describe SampleManifestExcel::Upload::Data, type: :model, sample_manifest_excel: true do

  include SampleManifestExcel::Helpers

  let(:test_file)               { 'test_file.xlsx' }
  let(:folder)                  { File.join('spec', 'data', 'sample_manifest_excel') }
  let(:yaml)                    { load_file(folder, 'columns') }
  let(:conditional_formattings) { SampleManifestExcel::ConditionalFormattingDefaultList.new(load_file(folder, 'conditional_formattings')) }
  let(:column_list)             { SampleManifestExcel::ColumnList.new(yaml, conditional_formattings) }
  let(:manifest_types)          { SampleManifestExcel::ManifestTypeList.new(load_file(folder, 'manifest_types')) }
  let(:columns)                 { column_list.extract(manifest_types.find_by(:tube_library_with_tag_sequences).columns) }
  let!(:download)               { build(:test_download, columns: columns) }
    
  before(:each) do
    download.save(test_file)
  end

  it 'is not valid without a filename' do
    expect(SampleManifestExcel::Upload::Data.new(nil, 9)).to_not be_valid
  end

  it 'is not valid without a start row' do
    expect(SampleManifestExcel::Upload::Data.new(test_file, nil)).to_not be_valid
  end

  it '#header_row returns the header columns' do
    data = SampleManifestExcel::Upload::Data.new(test_file, 9)
    spreadsheet = Roo::Spreadsheet.open(test_file).sheet(0)
    expect(data.header_row).to eq(spreadsheet.row(9))
  end

  it '#column returns a column of data' do
    data = SampleManifestExcel::Upload::Data.new(test_file, 9)
    spreadsheet = Roo::Spreadsheet.open(test_file).sheet(0)
    expect(data.column(spreadsheet.last_row - 1)).to eq(spreadsheet.column(spreadsheet.last_row - 1).drop(9))
  end

  it '#cell returns a cell of data' do
    data = SampleManifestExcel::Upload::Data.new(test_file, 9)
    spreadsheet = Roo::Spreadsheet.open(test_file).sheet(0)
    expect(data.cell(spreadsheet.last_row - 10, spreadsheet.last_column - 1)).to eq(spreadsheet.cell(spreadsheet.last_row - 10, spreadsheet.last_column - 1))
  end

  after(:each) do
    File.delete(test_file) if File.exist?(test_file)
  end
end
