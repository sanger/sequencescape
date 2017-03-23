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

    before(:each) do
      barcode = double('barcode')
      allow(barcode).to receive(:barcode).and_return(23)
      allow(PlateBarcode).to receive(:create).and_return(barcode)

      download.worksheet.sample_manifest.generate
      download.save(test_file)
      @upload = SampleManifestExcel::Upload::Base.new(filename: test_file, column_list: column_list, start_row: 9)
    end

    context '1dtube' do

      let!(:download)               { build(:test_download, columns: columns) }
      
      it 'will update the samples' do
        processor = SampleManifestExcel::Upload::Processor::OneDTube.new(upload)
        processor.run(tag_group)
        expect(processor).to be_samples_updated
        expect(upload.rows.all? { |row| row.sample_updated? }).to be_truthy
      end

      it 'will update the sample manifest' do
        processor = SampleManifestExcel::Upload::Processor::OneDTube.new(upload)
        processor.run(tag_group)
        expect(processor).to be_sample_manifest_updated
        expect(upload.sample_manifest.uploaded.filename).to eq(test_file)
      end
    end

    context 'Multiplexed Library Tube' do

      context 'valid' do
        let!(:download)               { build(:test_download, columns: columns, manifest_type: 'multiplexed_library') }

        it 'will update the samples' do
          processor = SampleManifestExcel::Upload::Processor::MultiplexedLibraryTube.new(upload)
          processor.run(tag_group)
          expect(processor).to be_samples_updated
          expect(upload.rows.all? { |row| row.sample_updated? }).to be_truthy
        end

        it 'will update the sample manifest' do
          processor = SampleManifestExcel::Upload::Processor::MultiplexedLibraryTube.new(upload)
          processor.run(tag_group)
          expect(processor).to be_sample_manifest_updated
          expect(upload.sample_manifest.uploaded.filename).to eq(test_file)
        end

        it 'will transfer the aliquots to the multiplexed library tube' do
          processor = SampleManifestExcel::Upload::Processor::MultiplexedLibraryTube.new(upload)
          processor.run(tag_group)
          expect(processor).to be_aliquots_transferred
          expect(upload.rows.all? { |row| row.aliquot_transferred? }).to be_truthy
        end
      end

      context 'mismatched tags' do
        let!(:download)               { build(:test_download, columns: columns, manifest_type: 'multiplexed_library', validation_errors: [:tags]) }

        it 'will not be valid' do
           processor = SampleManifestExcel::Upload::Processor::MultiplexedLibraryTube.new(upload)
           processor.run(tag_group)
           expect(processor).to_not be_valid
        end
      end

      
    end

    after(:each) do
      File.delete(test_file) if File.exist?(test_file)
    end

  end
end