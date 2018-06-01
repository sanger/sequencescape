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
    before(:all) do
      SampleManifestExcel.configure do |config|
        config.folder = File.join('spec', 'data', 'sample_manifest_excel')
        config.load!
      end
    end

    let(:test_file)               { 'test_file.xlsx' }
    let(:columns)                 { SampleManifestExcel.configuration.columns.tube_library_with_tag_sequences.dup }
    let!(:tag_group)              { create(:tag_group) }

    before(:each) do
      barcode = double('barcode')
      allow(barcode).to receive(:barcode).and_return(23)
      allow(PlateBarcode).to receive(:create).and_return(barcode)

      download.worksheet.sample_manifest.generate
      download.save(test_file)
      @upload = SampleManifestExcel::Upload::Base.new(filename: test_file, column_list: columns, start_row: 9)
    end

    context '1dtube' do
      let!(:download) { build(:test_download, columns: columns) }

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

      it 'will be processed' do
        processor = SampleManifestExcel::Upload::Processor::OneDTube.new(upload)
        processor.run(tag_group)
        expect(processor).to be_processed
      end
    end

    context 'Multiplexed Library Tube' do
      context 'valid' do
        let!(:download) { build(:test_download, columns: columns, manifest_type: 'multiplexed_library') }

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

        it 'will be processed' do
          processor = SampleManifestExcel::Upload::Processor::MultiplexedLibraryTube.new(upload)
          processor.run(tag_group)
          expect(processor).to be_processed
        end
      end

      context 'partial' do
        let!(:download) { build(:test_partial_download, manifest_type: 'multiplexed_library', columns: SampleManifestExcel.configuration.columns.tube_library_with_tag_sequences.dup) }

        it 'will process partial upload and cancel unprocessed requests' do
          processor = SampleManifestExcel::Upload::Processor::MultiplexedLibraryTube.new(upload)
          expect(upload.sample_manifest.pending_external_library_creation_requests.count).to eq 6
          processor.update_samples_and_aliquots(tag_group)
          expect(upload.sample_manifest.pending_external_library_creation_requests.count).to eq 2
          processor.cancel_unprocessed_external_library_creation_requests
          expect(upload.sample_manifest.pending_external_library_creation_requests.count).to eq 0
          processor.update_sample_manifest
          expect(processor).to be_processed
        end
      end

      context 'manifest reuploaded' do
        let!(:download) { build(:test_download, columns: columns, manifest_type: 'multiplexed_library') }
        let!(:new_test_file) { 'new_test_file.xlsx' }

        before(:each) do
          upload.process(tag_group)
          upload.complete
        end

        it 'will update the aliquots downstream if aliquots data has changed' do
          download.worksheet.axlsx_worksheet.rows[10].cells[6].value = '100'
          download.worksheet.axlsx_worksheet.rows[11].cells[7].value = '1000'
          download.save(new_test_file)
          reupload = SampleManifestExcel::Upload::Base.new(filename: new_test_file, column_list: columns, start_row: 9)
          processor = SampleManifestExcel::Upload::Processor::MultiplexedLibraryTube.new(reupload)
          processor.update_samples_and_aliquots(tag_group)
          expect(processor.substitutions[1]).to include('insert_size_from' => 100)
          expect(processor.substitutions[2]).to include('insert_size_to' => 1000)
          expect(processor.downstream_aliquots_updated?).to be_truthy
        end

        it 'will update the aliquots downstream if tags were swapped' do
          tag_oligo_1 = download.worksheet.axlsx_worksheet.rows[10].cells[2].value
          tag_oligo_2 = download.worksheet.axlsx_worksheet.rows[11].cells[2].value
          download.worksheet.axlsx_worksheet.rows[10].cells[2].value = tag_oligo_2
          download.worksheet.axlsx_worksheet.rows[11].cells[2].value = tag_oligo_1
          download.save(new_test_file)
          reupload = SampleManifestExcel::Upload::Base.new(filename: new_test_file, column_list: columns, start_row: 9)
          processor = SampleManifestExcel::Upload::Processor::MultiplexedLibraryTube.new(reupload)
          processor.update_samples_and_aliquots(tag_group)
          expect(processor.downstream_aliquots_updated?).to be_truthy
        end

        it 'will not update the aliquots downstream if there is nothing to update' do
          download.save(new_test_file)
          reupload = SampleManifestExcel::Upload::Base.new(filename: new_test_file, column_list: columns, start_row: 9)
          processor = SampleManifestExcel::Upload::Processor::MultiplexedLibraryTube.new(reupload)
          processor.update_samples_and_aliquots(tag_group)
          expect(processor.substitutions.compact).to be_empty
          expect(processor.downstream_aliquots_updated?).to be false
        end

        after(:each) do
          File.delete(new_test_file) if File.exist?(new_test_file)
        end
      end

      context 'mismatched tags' do
        let!(:download) { build(:test_download, columns: columns, manifest_type: 'multiplexed_library', validation_errors: [:tags]) }

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
