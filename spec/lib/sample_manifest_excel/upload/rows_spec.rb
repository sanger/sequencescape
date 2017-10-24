require 'rails_helper'

RSpec.describe SampleManifestExcel::Upload::Rows, type: :model, sample_manifest_excel: true do
  before(:all) do
    SampleManifestExcel.configure do |config|
      config.folder = File.join('spec', 'data', 'sample_manifest_excel')
      config.load!
    end
  end

  let(:test_file)               { 'test_file.xlsx' }
  let(:columns)                 { SampleManifestExcel.configuration.columns.tube_library_with_tag_sequences.dup }

  it 'is not valid without some data' do
    expect(SampleManifestExcel::Upload::Rows.new(nil, columns)).to_not be_valid
  end

  it 'is not valid without some columns' do
    download = build(:test_download, columns: columns)
    download.save(test_file)
    expect(SampleManifestExcel::Upload::Rows.new(SampleManifestExcel::Upload::Data.new(test_file, 9), nil)).to_not be_valid
  end

  it 'is not valid unless all of the rows are valid' do
    download = build(:test_download, columns: columns, validation_errors: [:insert_size_from])
    download.save(test_file)
    expect(SampleManifestExcel::Upload::Rows.new(SampleManifestExcel::Upload::Data.new(test_file, 9), columns)).to_not be_valid
  end

  it 'is valid if some rows are empty' do
    download = build(:test_partial_download, columns: columns)
    download.save(test_file)
    expect(SampleManifestExcel::Upload::Rows.new(SampleManifestExcel::Upload::Data.new(test_file, 9), columns)).to be_valid
  end

  it 'creates the row number relative to the start row' do
    download = build(:test_download, columns: columns, validation_errors: [:insert_size_from])
    download.save(test_file)
    rows = SampleManifestExcel::Upload::Rows.new(SampleManifestExcel::Upload::Data.new(test_file, 9), columns)
    expect(rows.first.number).to eq(10)
  end

  it 'knows values for all rows at particular column' do
    download = build(:test_download, columns: columns, validation_errors: [:insert_size_from])
    download.save(test_file)
    rows = SampleManifestExcel::Upload::Rows.new(SampleManifestExcel::Upload::Data.new(test_file, 9), columns)
    # column 6 is insert_size_from
    expect(rows.data_at(6)).to eq [nil, '200', '200', '200', '200', '200']
  end

  after(:each) do
    File.delete(test_file) if File.exist?(test_file)
  end

  after(:all) do
    SampleManifestExcel.reset!
  end
end
