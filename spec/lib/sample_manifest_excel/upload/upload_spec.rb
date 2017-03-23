require 'rails_helper'

RSpec.describe SampleManifestExcel::Upload, type: :model, sample_manifest_excel: true do
  include SampleManifestExcel::Helpers

  let(:test_file)               { 'test_file.xlsx' }
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

  it 'is not valid unless all of the rows are valid' do
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

  describe '#processor' do
    context '1dtube' do
      let!(:columns) { column_list.extract(manifest_types.find_by(:tube_library_with_tag_sequences).columns) }
      let!(:download) { build(:test_download, columns: columns) }

      before(:each) do
        download.save(test_file)
      end

      it 'should have the correct processor' do
        upload = SampleManifestExcel::Upload::Base.new(filename: test_file, column_list: column_list, start_row: 9)
        expect(upload.processor).to_not be_nil
        expect(upload.processor).to be_one_d_tube
      end

      it 'updates all of the data' do
        upload = SampleManifestExcel::Upload::Base.new(filename: test_file, column_list: column_list, start_row: 9)
        upload.process(tag_group)
        expect(upload.processor).to be_samples_updated
        expect(upload.processor).to be_sample_manifest_updated
      end
    end

    context 'multiplexed library tube' do
      let!(:columns) { column_list.extract(manifest_types.find_by(:tube_multiplexed_library_with_tag_sequences).columns) }
      let!(:download) { build(:test_download, columns: columns, manifest_type: 'multiplexed_library') }

      before(:each) do
        download.save(test_file)
      end

      it 'should have the correct processor' do
        download = build(:test_download, columns: columns, manifest_type: 'multiplexed_library')
        download.save(test_file)
        upload = SampleManifestExcel::Upload::Base.new(filename: test_file, column_list: column_list, start_row: 9)
        expect(upload.processor).to_not be_nil
        expect(upload.processor).to be_multiplexed_library_tube
      end

      it 'updates all of the data' do
        download = build(:test_download, columns: columns, manifest_type: 'multiplexed_library')
        download.save(test_file)
        upload = SampleManifestExcel::Upload::Base.new(filename: test_file, column_list: column_list, start_row: 9)
        upload.process(tag_group)
        expect(upload.processor).to be_samples_updated
        expect(upload.processor).to be_sample_manifest_updated
        expect(upload.processor).to be_aliquots_transferred
      end

      it 'fails if the tags are invalid' do
        download = build(:test_download, columns: columns, manifest_type: 'multiplexed_library', validation_errors: [:tags])
        download.save(test_file)
        upload = SampleManifestExcel::Upload::Base.new(filename: test_file, column_list: column_list, start_row: 9)
        upload.process(tag_group)
        expect(upload.processor).to_not be_samples_updated
        expect(upload.processor).to_not be_sample_manifest_updated
        expect(upload.processor).to_not be_aliquots_transferred
      end
    end
  end

  after(:each) do
    File.delete(test_file) if File.exist?(test_file)
  end
end
