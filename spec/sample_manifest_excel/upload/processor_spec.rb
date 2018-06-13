# frozen_string_literal: true

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

    let(:test_file) { 'test_file.xlsx' }

    describe 'for tube manifests' do
      let(:library_with_tag_seq_cols)            { SampleManifestExcel.configuration.columns.tube_library_with_tag_sequences.dup }
      let(:multiplex_library_with_tag_seq_cols)  { SampleManifestExcel.configuration.columns.tube_multiplexed_library_with_tag_sequences.dup }
      let(:multiplex_library_with_tag_grps_cols) { SampleManifestExcel.configuration.columns.tube_multiplexed_library.dup }
      let!(:tag_group)                           { create(:tag_group) }

      before(:each) do
        barcode = double('barcode')
        allow(barcode).to receive(:barcode).and_return(23)
        allow(PlateBarcode).to receive(:create).and_return(barcode)

        download.worksheet.sample_manifest.generate
        download.save(test_file)
      end

      context 'Library Tubes' do
        before(:each) do
          @upload = SampleManifestExcel::Upload::Base.new(filename: test_file, column_list: library_with_tag_seq_cols, start_row: 9)
        end

        context 'valid' do
          let!(:download) { build(:test_download, columns: library_with_tag_seq_cols, manifest_type: 'tube_library_with_tag_sequences') }

          it 'will update the samples' do
            processor = SampleManifestExcel::Upload::Processor::OneDTube.new(upload)
            processor.run(tag_group)
            expect(processor).to be_samples_updated
            expect(upload.rows.all?(&:sample_updated?)).to be_truthy
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

        context 'manifest reuploaded and overriden' do
          let!(:download) { build(:test_download, columns: library_with_tag_seq_cols, manifest_type: 'tube_library_with_tag_sequences') }
          let!(:new_test_file) { 'new_test_file.xlsx' }

          before(:each) do
            upload.process(tag_group)
            upload.complete
          end

          it 'will update the aliquots if aliquots data has changed and override is set true' do
            download.worksheet.axlsx_worksheet.rows[10].cells[11].value = '50'
            download.worksheet.axlsx_worksheet.rows[10].cells[12].value = 'Female'
            download.save(new_test_file)
            reupload = SampleManifestExcel::Upload::Base.new(filename: new_test_file, column_list: library_with_tag_seq_cols, start_row: 9, override: true)
            processor = SampleManifestExcel::Upload::Processor::OneDTube.new(reupload)
            processor.update_samples(tag_group)
            expect(reupload.rows.all?(&:sample_updated?)).to be_truthy
            s1 = Sample.find_by(sanger_sample_id: download.worksheet.axlsx_worksheet.rows[10].cells[1].value)
            expect(s1.sample_metadata.concentration).to eq('50')
            expect(s1.sample_metadata.gender).to eq('Female')
          end

          it 'will not update the aliquots if aliquots data has changed and override is set false' do
            download.worksheet.axlsx_worksheet.rows[10].cells[11].value = '50'
            download.worksheet.axlsx_worksheet.rows[10].cells[12].value = 'Female'
            download.save(new_test_file)
            reupload = SampleManifestExcel::Upload::Base.new(filename: new_test_file, column_list: library_with_tag_seq_cols, start_row: 9)
            processor = SampleManifestExcel::Upload::Processor::OneDTube.new(reupload)
            processor.update_samples(tag_group)
            expect(reupload.rows.all?(&:sample_updated?)).to be_falsey
            s1 = Sample.find_by(sanger_sample_id: download.worksheet.axlsx_worksheet.rows[10].cells[1].value)
            expect(s1.sample_metadata.concentration).to eq('1')
            expect(s1.sample_metadata.gender).to eq('Unknown')
          end

          after(:each) do
            File.delete(new_test_file) if File.exist?(new_test_file)
          end
        end
      end

      context 'Multiplexed Library Tubes with Tag Sequences' do
        before(:each) do
          @upload = SampleManifestExcel::Upload::Base.new(filename: test_file, column_list: multiplex_library_with_tag_seq_cols, start_row: 9)
        end

        context 'valid' do
          let!(:download) { build(:test_download, manifest_type: 'tube_multiplexed_library_with_tag_sequences', columns: multiplex_library_with_tag_seq_cols) }

          it 'will update the samples' do
            processor = SampleManifestExcel::Upload::Processor::MultiplexedLibraryTube.new(upload)
            processor.run(tag_group)
            expect(processor).to be_samples_updated
            expect(upload.rows.all?(&:sample_updated?)).to be_truthy
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
            expect(upload.rows.all?(&:aliquot_transferred?)).to be_truthy
          end

          it 'will be processed' do
            processor = SampleManifestExcel::Upload::Processor::MultiplexedLibraryTube.new(upload)
            processor.run(tag_group)
            expect(processor).to be_processed
          end
        end

        context 'partial' do
          let!(:download) { build(:test_partial_download, manifest_type: 'tube_multiplexed_library_with_tag_sequences', columns: multiplex_library_with_tag_seq_cols) }

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

        context 'manifest reuploaded and overriden' do
          let!(:download) { build(:test_download, manifest_type: 'tube_multiplexed_library_with_tag_sequences', columns: multiplex_library_with_tag_seq_cols) }
          let!(:new_test_file) { 'new_test_file.xlsx' }

          before(:each) do
            upload.process(tag_group)
            upload.complete
          end

          it 'will update the aliquots downstream if aliquots data has changed and override is set to true' do
            download.worksheet.axlsx_worksheet.rows[10].cells[6].value = '100'
            download.worksheet.axlsx_worksheet.rows[11].cells[7].value = '1000'
            download.save(new_test_file)
            reupload = SampleManifestExcel::Upload::Base.new(filename: new_test_file, column_list: multiplex_library_with_tag_seq_cols, start_row: 9, override: true)
            processor = SampleManifestExcel::Upload::Processor::MultiplexedLibraryTube.new(reupload)
            processor.update_samples_and_aliquots(tag_group)
            expect(processor.substitutions[1]).to include('insert_size_from' => 100)
            expect(processor.substitutions[2]).to include('insert_size_to' => 1000)
            expect(processor.downstream_aliquots_updated?).to be_truthy
          end

          it 'will update the aliquots downstream if tags were swapped and override is set to true' do
            tag_oligo_1 = download.worksheet.axlsx_worksheet.rows[10].cells[2].value
            tag_oligo_2 = download.worksheet.axlsx_worksheet.rows[11].cells[2].value
            download.worksheet.axlsx_worksheet.rows[10].cells[2].value = tag_oligo_2
            download.worksheet.axlsx_worksheet.rows[11].cells[2].value = tag_oligo_1
            download.save(new_test_file)
            reupload = SampleManifestExcel::Upload::Base.new(filename: new_test_file, column_list: multiplex_library_with_tag_seq_cols, start_row: 9, override: true)
            processor = SampleManifestExcel::Upload::Processor::MultiplexedLibraryTube.new(reupload)
            processor.update_samples_and_aliquots(tag_group)
            expect(processor.downstream_aliquots_updated?).to be_truthy
          end

          it 'will not update the aliquots downstream if there is nothing to update' do
            download.save(new_test_file)
            reupload = SampleManifestExcel::Upload::Base.new(filename: new_test_file, column_list: multiplex_library_with_tag_seq_cols, start_row: 9, override: true)
            processor = SampleManifestExcel::Upload::Processor::MultiplexedLibraryTube.new(reupload)
            processor.update_samples_and_aliquots(tag_group)
            expect(processor.substitutions.compact).to be_empty
            expect(processor.downstream_aliquots_updated?).to be_truthy
          end

          after(:each) do
            File.delete(new_test_file) if File.exist?(new_test_file)
          end
        end

        context 'mismatched tags' do
          let!(:download) { build(:test_download, manifest_type: 'tube_multiplexed_library_with_tag_sequences', columns: multiplex_library_with_tag_seq_cols, validation_errors: [:tags]) }

          it 'will not be valid' do
            processor = SampleManifestExcel::Upload::Processor::MultiplexedLibraryTube.new(upload)
            processor.run(tag_group)
            expect(processor).to_not be_valid
          end
        end
      end

      context 'Multiplexed Library Tubes with Tag Groups and Indexes' do
        before(:each) do
          @upload = SampleManifestExcel::Upload::Base.new(filename: test_file, column_list: multiplex_library_with_tag_grps_cols, start_row: 9)
        end

        context 'valid' do
          let!(:download) { build(:test_download, manifest_type: 'tube_multiplexed_library', columns: multiplex_library_with_tag_grps_cols) }

          it 'will update the samples' do
            processor = SampleManifestExcel::Upload::Processor::MultiplexedLibraryTube.new(upload)
            processor.run(nil)
            expect(processor).to be_samples_updated
            expect(upload.rows.all?(&:sample_updated?)).to be_truthy
          end

          it 'will update the sample manifest' do
            processor = SampleManifestExcel::Upload::Processor::MultiplexedLibraryTube.new(upload)
            processor.run(nil)
            expect(processor).to be_sample_manifest_updated
            expect(upload.sample_manifest.uploaded.filename).to eq(test_file)
          end

          it 'will transfer the aliquots to the multiplexed library tube' do
            processor = SampleManifestExcel::Upload::Processor::MultiplexedLibraryTube.new(upload)
            processor.run(nil)
            expect(processor).to be_aliquots_transferred
            expect(upload.rows.all?(&:aliquot_transferred?)).to be_truthy
          end

          it 'will be processed' do
            processor = SampleManifestExcel::Upload::Processor::MultiplexedLibraryTube.new(upload)
            processor.run(nil)
            expect(processor).to be_processed
          end
        end

        context 'partial' do
          let!(:download) { build(:test_partial_download, manifest_type: 'tube_multiplexed_library', columns: multiplex_library_with_tag_grps_cols) }

          it 'will process partial upload and cancel unprocessed requests' do
            processor = SampleManifestExcel::Upload::Processor::MultiplexedLibraryTube.new(upload)
            expect(upload.sample_manifest.pending_external_library_creation_requests.count).to eq 6
            processor.update_samples_and_aliquots(nil)
            expect(upload.sample_manifest.pending_external_library_creation_requests.count).to eq 2
            processor.cancel_unprocessed_external_library_creation_requests
            expect(upload.sample_manifest.pending_external_library_creation_requests.count).to eq 0
            processor.update_sample_manifest
            expect(processor).to be_processed
          end
        end

        context 'manifest reuploaded and overriden' do
          let!(:download) { build(:test_download, manifest_type: 'tube_multiplexed_library', columns: multiplex_library_with_tag_grps_cols) }
          let!(:new_test_file) { 'new_test_file.xlsx' }

          before(:each) do
            upload.process(nil)
            upload.complete
          end

          it 'will update the aliquots downstream if aliquots data has changed and override is set to true' do
            download.worksheet.axlsx_worksheet.rows[10].cells[7].value = '100'
            download.worksheet.axlsx_worksheet.rows[11].cells[8].value = '1000'
            download.save(new_test_file)
            reupload = SampleManifestExcel::Upload::Base.new(filename: new_test_file, column_list: multiplex_library_with_tag_grps_cols, start_row: 9, override: true)
            processor = SampleManifestExcel::Upload::Processor::MultiplexedLibraryTube.new(reupload)
            processor.update_samples_and_aliquots(nil)
            expect(processor.substitutions[1]).to include('insert_size_from' => 100)
            expect(processor.substitutions[2]).to include('insert_size_to' => 1000)
            expect(processor.downstream_aliquots_updated?).to be_truthy
          end

          it 'will update the aliquots downstream if tag indexes were swapped and override is set to true' do
            tag_group_1 = download.worksheet.axlsx_worksheet.rows[10].cells[2].value
            tag_index_1 = download.worksheet.axlsx_worksheet.rows[10].cells[3].value
            tag_group_2 = download.worksheet.axlsx_worksheet.rows[11].cells[2].value
            tag_index_2 = download.worksheet.axlsx_worksheet.rows[11].cells[3].value
            download.worksheet.axlsx_worksheet.rows[10].cells[2].value = tag_group_2
            download.worksheet.axlsx_worksheet.rows[10].cells[3].value = tag_index_2
            download.worksheet.axlsx_worksheet.rows[11].cells[2].value = tag_group_1
            download.worksheet.axlsx_worksheet.rows[11].cells[3].value = tag_index_1
            download.save(new_test_file)
            reupload = SampleManifestExcel::Upload::Base.new(filename: new_test_file, column_list: multiplex_library_with_tag_grps_cols, start_row: 9, override: true)
            processor = SampleManifestExcel::Upload::Processor::MultiplexedLibraryTube.new(reupload)
            processor.update_samples_and_aliquots(nil)
            expect(processor.downstream_aliquots_updated?).to be_truthy
          end

          it 'will not update the aliquots downstream if there is nothing to update' do
            download.save(new_test_file)
            reupload = SampleManifestExcel::Upload::Base.new(filename: new_test_file, column_list: multiplex_library_with_tag_grps_cols, start_row: 9, override: true)
            processor = SampleManifestExcel::Upload::Processor::MultiplexedLibraryTube.new(reupload)
            processor.update_samples_and_aliquots(nil)
            expect(processor.substitutions.compact).to be_empty
            expect(processor.downstream_aliquots_updated?).to be_truthy
          end

          after(:each) do
            File.delete(new_test_file) if File.exist?(new_test_file)
          end
        end

        context 'mismatched tags' do
          let!(:download) { build(:test_download, manifest_type: 'tube_multiplexed_library', columns: multiplex_library_with_tag_grps_cols, validation_errors: [:tags]) }

          it 'will not be valid' do
            processor = SampleManifestExcel::Upload::Processor::MultiplexedLibraryTube.new(upload)
            processor.run(nil)
            expect(processor).to_not be_valid
          end
        end
      end
    end

    context 'Plates' do
      let(:plate_columns) { SampleManifestExcel.configuration.columns.plate_default.dup }

      before(:each) do
        barcode = double('barcode')
        allow(barcode).to receive(:barcode).and_return(23)
        allow(PlateBarcode).to receive(:create).and_return(barcode)

        download.worksheet.sample_manifest.generate
        download.save(test_file)
        @upload = SampleManifestExcel::Upload::Base.new(filename: test_file, column_list: plate_columns, start_row: 9)
      end

      context 'valid' do
        let!(:download)     { build(:test_download_plates, columns: plate_columns) }

        it 'will update the samples' do
          processor = SampleManifestExcel::Upload::Processor::Plate.new(upload)
          processor.run(nil)
          expect(processor).to be_samples_updated
          expect(upload.rows.all?(&:sample_updated?)).to be_truthy
        end

        it 'will update the sample manifest' do
          processor = SampleManifestExcel::Upload::Processor::Plate.new(upload)
          processor.run(nil)
          expect(processor).to be_sample_manifest_updated
          expect(upload.sample_manifest.uploaded.filename).to eq(test_file)
        end

        it 'will be processed' do
          processor = SampleManifestExcel::Upload::Processor::Plate.new(upload)
          processor.run(nil)
          expect(processor).to be_processed
        end

        context 'partial' do
          let!(:download) { build(:test_download_plates_partial, columns: plate_columns) }

          it 'will process a partial upload' do
            processor = SampleManifestExcel::Upload::Processor::Plate.new(upload)
            expect(upload.sample_manifest.samples.map do |sample|
              sample.reload
              sample.sample_metadata.concentration.nil?
            end.count).to eq(4)
            processor.update_samples(nil)
            expect(upload.sample_manifest.samples.map do |sample|
              sample.reload
              sample.sample_metadata.concentration.nil?
            end.count(true)).to eq(2)
            processor.update_sample_manifest
            expect(processor).to be_processed
          end
        end

        context 'when using foreign barcodes' do
          let!(:download)     { build(:test_download_plates_cgap, columns: plate_columns) }

          it 'will update the samples' do
            processor = SampleManifestExcel::Upload::Processor::Plate.new(upload)
            processor.run(nil)
            expect(processor).to be_samples_updated
            expect(upload.rows.all?(&:sample_updated?)).to be_truthy
          end

          it 'will update the sample manifest' do
            processor = SampleManifestExcel::Upload::Processor::Plate.new(upload)
            processor.run(nil)
            expect(processor).to be_sample_manifest_updated
            expect(upload.sample_manifest.uploaded.filename).to eq(test_file)
          end

          it 'will be processed' do
            processor = SampleManifestExcel::Upload::Processor::Plate.new(upload)
            processor.run(nil)
            expect(processor).to be_processed
          end

          context 'partial' do
            let!(:download) { build(:test_download_plates_partial_cgap, columns: plate_columns) }

            it 'will process a partial upload' do
              processor = SampleManifestExcel::Upload::Processor::Plate.new(upload)
              expect(upload.sample_manifest.samples.map do |sample|
                sample.reload
                sample.sample_metadata.concentration.nil?
              end.count).to eq(4)
              processor.update_samples(nil)
              expect(upload.sample_manifest.samples.map do |sample|
                sample.reload
                sample.sample_metadata.concentration.nil?
              end.count(true)).to eq(2)
              processor.update_sample_manifest
              expect(processor).to be_processed
            end
          end
        end

        context 'manifest reuploaded and overriden' do
          let!(:download) { build(:test_download_plates, columns: plate_columns) }
          let!(:new_test_file) { 'new_test_file.xlsx' }

          before(:each) do
            upload.process(nil)
            upload.complete
          end

          it 'will update the aliquots if aliquots data has changed and override is set true' do
            download.worksheet.axlsx_worksheet.rows[10].cells[6].value = '50'
            download.worksheet.axlsx_worksheet.rows[10].cells[7].value = 'Female'
            download.save(new_test_file)
            reupload = SampleManifestExcel::Upload::Base.new(filename: new_test_file, column_list: plate_columns, start_row: 9, override: true)
            processor = SampleManifestExcel::Upload::Processor::Plate.new(reupload)
            processor.update_samples(nil)
            expect(reupload.rows.all?(&:sample_updated?)).to be_truthy
            s1 = Sample.find_by(sanger_sample_id: download.worksheet.axlsx_worksheet.rows[10].cells[2].value)
            expect(s1.sample_metadata.concentration).to eq('50')
            expect(s1.sample_metadata.gender).to eq('Female')
          end

          it 'will not update the aliquots if aliquots data has changed and override is set false' do
            download.worksheet.axlsx_worksheet.rows[10].cells[6].value = '50'
            download.worksheet.axlsx_worksheet.rows[10].cells[7].value = 'Female'
            download.save(new_test_file)
            reupload = SampleManifestExcel::Upload::Base.new(filename: new_test_file, column_list: plate_columns, start_row: 9)
            processor = SampleManifestExcel::Upload::Processor::Plate.new(reupload)
            processor.update_samples(nil)
            expect(reupload.rows.all?(&:sample_updated?)).to be_falsey
            s1 = Sample.find_by(sanger_sample_id: download.worksheet.axlsx_worksheet.rows[10].cells[2].value)
            expect(s1.sample_metadata.concentration).to eq('1')
            expect(s1.sample_metadata.gender).to eq('Unknown')
          end

          after(:each) do
            File.delete(new_test_file) if File.exist?(new_test_file)
          end
        end
      end

      context 'invalid' do
        context 'when using foreign barcodes' do
          let!(:download)     { build(:test_download_plates_cgap, columns: plate_columns, validation_errors: [:sample_plate_id_duplicates]) }

          it 'duplicates will not be valid' do
            processor = SampleManifestExcel::Upload::Processor::Plate.new(upload)
            expect(processor).to_not be_valid
          end
        end
      end
    end

    after(:each) do
      File.delete(test_file) if File.exist?(test_file)
    end
  end
end
