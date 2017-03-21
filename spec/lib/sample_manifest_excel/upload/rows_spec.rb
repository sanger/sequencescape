require 'rails_helper'

RSpec.describe SampleManifestExcel::Upload::Rows, type: :model, sample_manifest_excel: true do

  include SampleManifestExcel::Helpers

  let(:test_file)               { 'test_file.xlsx' }
  let(:folder)                  { File.join('spec', 'data', 'sample_manifest_excel') }
  let(:yaml)                    { load_file(folder, 'columns') }
  let(:conditional_formattings) { SampleManifestExcel::ConditionalFormattingDefaultList.new(load_file(folder, 'conditional_formattings')) }
  let(:column_list)             { SampleManifestExcel::ColumnList.new(yaml, conditional_formattings) }
  let(:manifest_types)          { SampleManifestExcel::ManifestTypeList.new(load_file(folder, 'manifest_types')) }
  let(:columns)                 { column_list.extract(manifest_types.find_by(:tube_library_with_tag_sequences).columns) }

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

  after(:each) do
    File.delete(test_file) if File.exist?(test_file)
  end

end
