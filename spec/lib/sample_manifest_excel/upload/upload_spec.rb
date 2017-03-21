require 'rails_helper'

RSpec.describe SampleManifestExcel::Upload, type: :model, sample_manifest_excel: true do

  include SampleManifestExcel::Helpers

  let(:test_file)               { 'test_file.xlsx'}
  let(:folder)                  { File.join('spec', 'data', 'sample_manifest_excel') }
  let(:yaml)                    { load_file(folder, 'columns') }
  let(:conditional_formattings) { SampleManifestExcel::ConditionalFormattingDefaultList.new(load_file(folder, 'conditional_formattings')) }
  let(:column_list)             { SampleManifestExcel::ColumnList.new(yaml, conditional_formattings) }
  let(:manifest_types)          { SampleManifestExcel::ManifestTypeList.new(load_file(folder, 'manifest_types')) }
  let!(:tag_group)              { create(:tag_group) }

  it 'is valid if all of the headings relate to a column' do
    columns = column_list.extract(manifest_types.find_by(:tube_library_with_tag_sequences).columns)
    download = build(:test_download, columns: columns)
    download.save(test_file)
    upload = SampleManifestExcel::Upload::Base.new(filename: test_file, column_list: column_list, start_row: 9)
    expect(upload.columns.count).to eq(columns.count)
    expect(upload).to be_valid
  end

  it 'is invalid if any of the headings do not relate to a column' do
    download = build(:test_download, columns: column_list.extract(manifest_types.find_by(:tube_library_with_tag_sequences).columns).with(:my_dodgy_column))
    download.save(test_file)
    upload = SampleManifestExcel::Upload::Base.new(filename: test_file, column_list: column_list, start_row: 9)
    expect(upload).to_not be_valid
    expect(upload.errors.full_messages.to_s).to include(upload.columns.bad_keys.first)
  end

  it 'is invalid if there is no sanger sample id column' do
    download = build(:test_download, columns: column_list.extract(manifest_types.find_by(:tube_library_with_tag_sequences).columns).except(:sanger_sample_id))
    download.save(test_file)
    upload = SampleManifestExcel::Upload::Base.new(filename: test_file, column_list: column_list, start_row: 9)
    expect(upload).to_not be_valid
  end

  it "is invalid if tags are not valid" do
    download = build(:test_download, columns: column_list.extract(manifest_types.find_by(:tube_library_with_tag_sequences).columns), validation_errors: [:tags])
    download.save(test_file)
    upload = SampleManifestExcel::Upload::Base.new(filename: test_file, column_list: column_list, start_row: 9)
    expect(upload).to_not be_valid
  end

  it "is not valid unless all of the rows are valid" do
    download = build(:test_download, columns: column_list.extract(manifest_types.find_by(:tube_library_with_tag_sequences).columns), validation_errors: [:library_type])
    download.save(test_file)
    upload = SampleManifestExcel::Upload::Base.new(filename: test_file, column_list: column_list, start_row: 9)
    expect(upload).to_not be_valid

    download = build(:test_download, columns: column_list.extract(manifest_types.find_by(:tube_library_with_tag_sequences).columns), validation_errors: [:insert_size_from])
    download.save(test_file)
    upload = SampleManifestExcel::Upload::Base.new(filename: test_file, column_list: column_list, start_row: 9)
    expect(upload).to_not be_valid
  end

  it 'is not valid unless there is an associated sample manifest' do
    download = build(:test_download, columns: column_list.extract(manifest_types.find_by(:tube_library_with_tag_sequences).columns), validation_errors: [:sample_manifest])
    download.save(test_file)

    upload = SampleManifestExcel::Upload::Base.new(filename: test_file, column_list: column_list, start_row: 9)
    expect(upload).to_not be_valid
  end

  it "updates all of the data" do
    columns = column_list.extract(manifest_types.find_by(:tube_library_with_tag_sequences).columns)
    download = build(:test_download, columns: columns)
    download.save(test_file)
    upload = SampleManifestExcel::Upload::Base.new(filename: test_file, column_list: column_list, start_row: 9)
    upload.update_samples(tag_group)
    expect(upload.rows).to_not be_empty
    expect(upload.rows.all? { |row| row.sample_updated? }).to be_truthy
    expect(upload.rows.first.sample.aliquots.first.insert_size_from).to_not be_nil
    expect(upload.rows.last.sample.aliquots.first.insert_size_from).to_not be_nil
    expect(upload.rows.first.sample.sample_metadata.concentration).to_not be_nil
    expect(upload.rows.last.sample.sample_metadata.concentration).to_not be_nil
  end

  it 'updates the sample manifest' do
    columns = column_list.extract(manifest_types.find_by(:tube_library_with_tag_sequences).columns)
    download = build(:test_download, columns: columns)
    download.save(test_file)
    upload = SampleManifestExcel::Upload::Base.new(filename: test_file, column_list: column_list, start_row: 9)
    upload.update_sample_manifest
    expect(upload.sample_manifest.uploaded.filename).to eq(test_file)
  end

  after(:each) do
    File.delete(test_file) if File.exist?(test_file)
  end

end
