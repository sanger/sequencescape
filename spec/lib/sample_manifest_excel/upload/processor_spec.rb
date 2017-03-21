require 'rails_helper'

RSpec.describe SampleManifestExcel::Upload::Processor, type: :model, sample_manifest_excel: true do

  include SampleManifestExcel::Helpers

  attr_reader :upload

  FakeUpload = Struct.new(:name, :id)

  it 'is not valid without an upload' do
    expect(SampleManifestExcel::Upload::Processor::Base.new(FakeUpload.new)).to_not be_valid
    expect(SampleManifestExcel::Upload::Processor::Base.new(nil)).to_not be_valid
  end

  describe '#run' do

    let(:test_file)               { 'test_file.xlsx'}
    let(:folder)                  { File.join('spec', 'data', 'sample_manifest_excel') }
    let(:yaml)                    { load_file(folder, 'columns') }
    let(:conditional_formattings) { SampleManifestExcel::ConditionalFormattingDefaultList.new(load_file(folder, 'conditional_formattings')) }
    let(:column_list)             { SampleManifestExcel::ColumnList.new(yaml, conditional_formattings) }
    let(:manifest_types)          { SampleManifestExcel::ManifestTypeList.new(load_file(folder, 'manifest_types')) }
    let!(:tag_group)              { create(:tag_group) }
    let(:columns)                 { column_list.extract(manifest_types.find_by(:tube_library_with_tag_sequences).columns) }
    let!(:download)               { build(:test_download, columns: columns) }

    before(:each) do
      download.save(test_file)
      @upload = SampleManifestExcel::Upload::Base.new(filename: test_file, column_list: column_list, start_row: 9)
    end

    it 'will update the samples' do
      processor = SampleManifestExcel::Upload::Processor::Base.new(upload)
      processor.run(tag_group)
      expect(upload.rows.all? { |row| row.sample_updated? }).to be_truthy
      expect(upload.rows.first.sample.aliquots.first.insert_size_from).to_not be_nil
      expect(upload.rows.last.sample.aliquots.first.insert_size_from).to_not be_nil
      expect(upload.rows.first.sample.sample_metadata.concentration).to_not be_nil
      expect(upload.rows.last.sample.sample_metadata.concentration).to_not be_nil
    end

    it 'will update the sample manifest' do
      processor = SampleManifestExcel::Upload::Processor::Base.new(upload)
      processor.run(tag_group)
      expect(upload.sample_manifest.uploaded.filename).to eq(test_file)
    end
  end
end