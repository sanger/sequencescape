# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SampleManifestExcel::Upload::Processor, type: :model, sample_manifest_excel: true, sample_manifest: true do
  include SequencescapeExcel::Helpers

  attr_reader :upload

  FakeUpload = Struct.new(:name, :id)

  it 'is not valid without an upload' do
    expect(SampleManifestExcel::Upload::Processor::Base.new(FakeUpload.new)).not_to be_valid
    expect(SampleManifestExcel::Upload::Processor::Base.new(nil)).not_to be_valid
  end

  describe '#run' do
    let(:configuration) do
      SampleManifestExcel::Configuration.new do |config|
        config.folder = File.join('spec', 'data', 'sample_manifest_excel')
        config.load!
      end
    end

    let(:test_file_name) { 'test_file.xlsx' }
    let(:test_file) { Rack::Test::UploadedFile.new(Rails.root.join(test_file_name), '') }

    after do
      File.delete(test_file_name) if File.exist?(test_file_name)
    end

    describe 'for tube manifests' do
      let(:library_with_tag_seq_cols)            { configuration.columns.tube_library_with_tag_sequences }
      let(:multiplex_library_with_tag_seq_cols)  { configuration.columns.tube_multiplexed_library_with_tag_sequences }
      let(:multiplex_library_with_tag_grps_cols) { configuration.columns.tube_multiplexed_library }
      let(:tag_group) { create(:tag_group) }

      before do
        barcode = double('barcode')
        allow(barcode).to receive(:barcode).and_return(23)
        allow(PlateBarcode).to receive(:create).and_return(barcode)

        download.worksheet.sample_manifest.generate
        download.save(test_file_name)
      end

      describe 'SampleManifestExcel::Upload::Processor::OneDTube' do
        let(:upload) { SampleManifestExcel::Upload::Base.new(file: test_file, column_list: library_with_tag_seq_cols, start_row: 9) }
        let(:processor) { SampleManifestExcel::Upload::Processor::OneDTube.new(upload) }

        context 'when valid' do
          let(:download) { build(:test_download_tubes, columns: library_with_tag_seq_cols, manifest_type: 'tube_library_with_tag_sequences') }

          it 'will not generate samples prior to processing' do
            expect { upload }.not_to change(Sample, :count)
          end

          it 'will process', :aggregate_failures do
            processor.run(tag_group)

            aggregate_failures 'update samples' do
              expect(processor).to be_samples_updated
              expect(upload.rows).to be_all(&:sample_updated?)
            end

            aggregate_failures 'update sample manifest' do
              expect(processor).to be_sample_manifest_updated
              expect(upload.sample_manifest.uploaded.filename).to eq(test_file_name)
            end

            expect(processor).to be_processed
          end
        end

        context 'manifest reuploaded and overriden' do
          let(:download) { build(:test_download_tubes, columns: library_with_tag_seq_cols, manifest_type: 'tube_library_with_tag_sequences') }
          let(:new_test_file_name) { 'new_test_file.xlsx' }
          let(:new_test_file) { Rack::Test::UploadedFile.new(Rails.root.join(new_test_file_name), '') }
          let(:reupload) { SampleManifestExcel::Upload::Base.new(file: new_test_file, column_list: library_with_tag_seq_cols, start_row: 9, override: override) }
          let(:processor) { SampleManifestExcel::Upload::Processor::OneDTube.new(reupload) }

          before do
            upload.process(tag_group)
            upload.complete
            download.worksheet.axlsx_worksheet.rows[10].cells[11].value = '50'
            download.worksheet.axlsx_worksheet.rows[10].cells[12].value = 'Female'
            download.save(new_test_file_name)

            processor.update_samples(tag_group)
          end

          after do
            File.delete(new_test_file) if File.exist?(new_test_file_name)
          end

          context 'when override is true' do
            let(:override) { true }

            it 'will update the aliquots if aliquots data has changed' do
              expect(reupload.rows).to be_all(&:sample_updated?)
              s1 = Sample.find_by(sanger_sample_id: download.worksheet.axlsx_worksheet.rows[10].cells[1].value)
              expect(s1.sample_metadata.concentration).to eq('50')
              expect(s1.sample_metadata.gender).to eq('Female')
            end
          end

          context 'when override is false' do
            let(:override) { false }

            it 'will not update the aliquots if aliquots data has changed' do
              expect(reupload.rows).not_to be_all(&:sample_updated?)
              s1 = Sample.find_by(sanger_sample_id: download.worksheet.axlsx_worksheet.rows[10].cells[1].value)
              expect(s1.sample_metadata.concentration).to eq('1')
              expect(s1.sample_metadata.gender).to eq('Unknown')
            end
          end
        end
      end

      describe 'SampleManifestExcel::Upload::Processor::MultiplexedLibraryTube' do
        let(:upload) { SampleManifestExcel::Upload::Base.new(file: test_file, column_list: multiplex_library_with_tag_seq_cols, start_row: 9) }
        let(:processor) { SampleManifestExcel::Upload::Processor::MultiplexedLibraryTube.new(upload) }

        context 'when valid' do
          let(:download) { build(:test_download_tubes, manifest_type: 'tube_multiplexed_library_with_tag_sequences', columns: multiplex_library_with_tag_seq_cols) }

          it 'will not generate samples prior to processing' do
            expect { upload }.not_to change(Sample, :count)
          end

          it 'will transfer the aliquots to the multiplexed library tube' do
            processor.run(tag_group)
            expect(processor).to be_aliquots_transferred
            expect(upload.rows).to be_all(&:aliquot_transferred?)
          end

          it 'will process', :aggregate_failures do
            processor.run(tag_group)

            aggregate_failures 'update samples' do
              expect(processor).to be_samples_updated
              expect(upload.rows).to be_all(&:sample_updated?)
            end

            aggregate_failures 'update sample manifest' do
              expect(processor).to be_sample_manifest_updated
              expect(upload.sample_manifest.uploaded.filename).to eq(test_file_name)
            end

            expect(processor).to be_processed
          end
        end

        context 'partial' do
          let(:download) { build(:test_download_tubes_partial, manifest_type: 'tube_multiplexed_library_with_tag_sequences', columns: multiplex_library_with_tag_seq_cols) }

          it 'will process partial upload and cancel unprocessed requests' do
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
          let(:download) { build(:test_download_tubes, manifest_type: 'tube_multiplexed_library_with_tag_sequences', columns: multiplex_library_with_tag_seq_cols) }
          let(:new_test_file_name) { 'new_test_file.xlsx' }
          let(:new_test_file) { Rack::Test::UploadedFile.new(Rails.root.join(new_test_file_name), '') }

          before do
            upload.process(tag_group)
            upload.complete
          end

          after do
            File.delete(new_test_file_name) if File.exist?(new_test_file_name)
          end

          it 'will update the aliquots downstream if aliquots data has changed and override is set to true' do
            download.worksheet.axlsx_worksheet.rows[10].cells[6].value = '100'
            download.worksheet.axlsx_worksheet.rows[11].cells[7].value = '1000'
            download.save(new_test_file_name)
            reupload = SampleManifestExcel::Upload::Base.new(file: new_test_file, column_list: multiplex_library_with_tag_seq_cols, start_row: 9, override: true)
            processor = SampleManifestExcel::Upload::Processor::MultiplexedLibraryTube.new(reupload)
            processor.update_samples_and_aliquots(tag_group)
            expect(processor.substitutions[1]).to include('insert_size_from' => 100)
            expect(processor.substitutions[2]).to include('insert_size_to' => 1000)
            expect(processor).to be_downstream_aliquots_updated
          end

          it 'will update the aliquots downstream if tags were swapped and override is set to true' do
            i7_1 = download.worksheet.axlsx_worksheet.rows[10].cells[2].value
            i7_2 = download.worksheet.axlsx_worksheet.rows[11].cells[2].value
            download.worksheet.axlsx_worksheet.rows[10].cells[2].value = i7_2
            download.worksheet.axlsx_worksheet.rows[11].cells[2].value = i7_1
            download.save(new_test_file_name)
            reupload = SampleManifestExcel::Upload::Base.new(file: new_test_file, column_list: multiplex_library_with_tag_seq_cols, start_row: 9, override: true)
            processor = SampleManifestExcel::Upload::Processor::MultiplexedLibraryTube.new(reupload)
            processor.update_samples_and_aliquots(tag_group)
            expect(processor).to be_downstream_aliquots_updated
          end

          it 'will update the aliquots downstream in dual index cases where the subtitured tags along look like a tag clash' do
            # We already have distinct tag2s, so by setting these to the same, we aren't creating a tag clash.
            download.worksheet.axlsx_worksheet.rows[10].cells[2].value = 'ATAGATAGATAG'
            download.worksheet.axlsx_worksheet.rows[11].cells[2].value = 'ATAGATAGATAG'
            download.save(new_test_file_name)
            reupload = SampleManifestExcel::Upload::Base.new(file: new_test_file, column_list: multiplex_library_with_tag_seq_cols, start_row: 9, override: true)
            processor = SampleManifestExcel::Upload::Processor::MultiplexedLibraryTube.new(reupload)
            processor.update_samples_and_aliquots(tag_group)
            expect(processor).to be_aliquots_updated
            expect(processor).to be_downstream_aliquots_updated
          end

          it 'will not update the aliquots downstream if there is nothing to update' do
            download.save(new_test_file_name)
            reupload = SampleManifestExcel::Upload::Base.new(file: new_test_file, column_list: multiplex_library_with_tag_seq_cols, start_row: 9, override: true)
            processor = SampleManifestExcel::Upload::Processor::MultiplexedLibraryTube.new(reupload)
            processor.update_samples_and_aliquots(tag_group)
            expect(processor.substitutions.compact).to be_empty
            expect(processor).not_to be_downstream_aliquots_updated
          end
        end

        context 'mismatched tags' do
          let(:download) { build(:test_download_tubes, manifest_type: 'tube_multiplexed_library_with_tag_sequences', columns: multiplex_library_with_tag_seq_cols, validation_errors: [:tags]) }

          it 'will not be valid' do
            processor = SampleManifestExcel::Upload::Processor::MultiplexedLibraryTube.new(upload)
            processor.run(tag_group)
            expect(processor).not_to be_valid
          end
        end
      end

      context 'Multiplexed Library Tubes with Tag Groups and Indexes' do
        let(:upload) { SampleManifestExcel::Upload::Base.new(file: test_file, column_list: multiplex_library_with_tag_grps_cols, start_row: 9) }

        context 'when valid' do
          let(:download) { build(:test_download_tubes, manifest_type: 'tube_multiplexed_library', columns: multiplex_library_with_tag_grps_cols) }
          let(:processor) { SampleManifestExcel::Upload::Processor::MultiplexedLibraryTube.new(upload) }

          it 'will process', :aggregate_failures do
            processor.run(nil)

            aggregate_failures 'update samples' do
              expect(processor).to be_samples_updated
              expect(upload.rows).to be_all(&:sample_updated?)
            end

            aggregate_failures 'update sample manifest' do
              expect(processor).to be_sample_manifest_updated
              expect(upload.sample_manifest.uploaded.filename).to eq(test_file_name)
            end

            expect(processor).to be_processed
          end

          it 'will transfer the aliquots to the multiplexed library tube' do
            processor.run(nil)
            expect(processor).to be_aliquots_transferred
            expect(upload.rows).to be_all(&:aliquot_transferred?)
          end
        end

        context 'partial' do
          let(:download) { build(:test_download_tubes_partial, manifest_type: 'tube_multiplexed_library', columns: multiplex_library_with_tag_grps_cols) }

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
          let(:download) { build(:test_download_tubes, manifest_type: 'tube_multiplexed_library', columns: multiplex_library_with_tag_grps_cols) }
          let(:new_test_file_name) { 'new_test_file.xlsx' }
          let(:new_test_file) { Rack::Test::UploadedFile.new(Rails.root.join(new_test_file_name), '') }

          before do
            upload.process(nil)
            upload.complete
          end

          after do
            File.delete(new_test_file_name) if File.exist?(new_test_file_name)
          end

          it 'will update the aliquots downstream if aliquots data has changed and override is set to true' do
            download.worksheet.axlsx_worksheet.rows[10].cells[7].value = '100'
            download.worksheet.axlsx_worksheet.rows[11].cells[8].value = '1000'
            download.save(new_test_file_name)
            reupload = SampleManifestExcel::Upload::Base.new(file: new_test_file, column_list: multiplex_library_with_tag_grps_cols, start_row: 9, override: true)
            processor = SampleManifestExcel::Upload::Processor::MultiplexedLibraryTube.new(reupload)
            processor.update_samples_and_aliquots(nil)
            expect(processor.substitutions[1]).to include('insert_size_from' => 100)
            expect(processor.substitutions[2]).to include('insert_size_to' => 1000)
            expect(processor).to be_downstream_aliquots_updated
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
            download.save(new_test_file_name)
            reupload = SampleManifestExcel::Upload::Base.new(file: new_test_file, column_list: multiplex_library_with_tag_grps_cols, start_row: 9, override: true)
            processor = SampleManifestExcel::Upload::Processor::MultiplexedLibraryTube.new(reupload)
            processor.update_samples_and_aliquots(nil)
            expect(processor).to be_downstream_aliquots_updated
          end

          it 'will not update the aliquots downstream if there is nothing to update' do
            download.save(new_test_file_name)
            reupload = SampleManifestExcel::Upload::Base.new(file: new_test_file, column_list: multiplex_library_with_tag_grps_cols, start_row: 9, override: true)
            processor = SampleManifestExcel::Upload::Processor::MultiplexedLibraryTube.new(reupload)
            processor.update_samples_and_aliquots(nil)
            expect(processor.substitutions.compact).to be_empty
            expect(processor).not_to be_downstream_aliquots_updated
          end
        end

        context 'mismatched tags' do
          let(:download) { build(:test_download_tubes, manifest_type: 'tube_multiplexed_library', columns: multiplex_library_with_tag_grps_cols, validation_errors: [:tags]) }

          it 'will not be valid' do
            processor = SampleManifestExcel::Upload::Processor::MultiplexedLibraryTube.new(upload)
            processor.run(nil)
            expect(processor).not_to be_valid
          end
        end
      end
    end

    describe 'SampleManifestExcel::Upload::Processor::Plate' do
      let(:plate_columns) { configuration.columns.plate_default.dup }
      let(:upload) { SampleManifestExcel::Upload::Base.new(file: test_file, column_list: plate_columns, start_row: 9) }
      let(:processor) { SampleManifestExcel::Upload::Processor::Plate.new(upload) }

      before do
        barcode = double('barcode')
        allow(barcode).to receive(:barcode).and_return(23)
        allow(PlateBarcode).to receive(:create).and_return(barcode)

        download.worksheet.sample_manifest.generate
        download.save(test_file_name)
      end

      context 'when valid' do
        let(:download) { build(:test_download_plates, columns: plate_columns) }

        it 'will not generate samples prior to processing' do
          expect { processor }.not_to change(Sample, :count)
        end

        it 'will process', :aggregate_failures do
          processor.run(nil)

          aggregate_failures 'update samples' do
            expect(processor).to be_samples_updated
            expect(upload.rows).to be_all(&:sample_updated?)
          end

          aggregate_failures 'update sample manifest' do
            expect(processor).to be_sample_manifest_updated
            expect(upload.sample_manifest.uploaded.filename).to eq(test_file_name)
          end

          expect(processor).to be_processed
        end

        context 'partial' do
          let(:download) { build(:test_download_plates_partial, columns: plate_columns) }

          it 'will process a partial upload' do
            processor.update_samples(nil)
            expect(upload.sample_manifest.samples.map do |sample|
              sample.reload
              sample.sample_metadata.concentration.present?
            end.count(true)).to eq(2)
            processor.update_sample_manifest
            expect(processor).to be_processed
          end
        end

        context 'when using foreign barcodes' do
          let(:download) { build(:test_download_plates_cgap, columns: plate_columns) }

          it 'will process', :aggregate_failures do
            processor.run(nil)

            aggregate_failures 'update samples' do
              expect(processor).to be_samples_updated
              expect(upload.rows).to be_all(&:sample_updated?)
            end

            aggregate_failures 'update sample manifest' do
              expect(processor).to be_sample_manifest_updated
              expect(upload.sample_manifest.uploaded.filename).to eq(test_file_name)
            end

            expect(processor).to be_processed
          end

          context 'partial' do
            let(:download) { build(:test_download_plates_partial_cgap, columns: plate_columns) }

            it 'will process a partial upload' do
              processor.update_samples(nil)
              expect(upload.sample_manifest.samples.reload.count do |sample|
                sample.reload
                sample.sample_metadata.concentration.present?
              end).to eq(2)
              processor.update_sample_manifest
              expect(processor).to be_processed
            end
          end
        end

        context 'manifest reuploaded and overriden' do
          let(:download) { build(:test_download_plates, columns: plate_columns) }
          let(:new_test_file_name) { 'new_test_file.xlsx' }
          let(:new_test_file) { Rack::Test::UploadedFile.new(Rails.root.join(new_test_file_name), '') }

          before do
            upload.process(nil)
            upload.complete
          end

          after do
            File.delete(new_test_file_name) if File.exist?(new_test_file_name)
          end

          it 'will update the aliquots if aliquots data has changed and override is set true' do
            download.worksheet.axlsx_worksheet.rows[10].cells[6].value = '50'
            download.worksheet.axlsx_worksheet.rows[10].cells[7].value = 'Female'
            download.save(new_test_file_name)
            reupload = SampleManifestExcel::Upload::Base.new(file: new_test_file, column_list: plate_columns, start_row: 9, override: true)
            processor = SampleManifestExcel::Upload::Processor::Plate.new(reupload)
            processor.update_samples(nil)
            expect(reupload.rows).to be_all(&:sample_updated?)
            s1 = Sample.find_by(sanger_sample_id: download.worksheet.axlsx_worksheet.rows[10].cells[2].value)
            expect(s1.sample_metadata.concentration).to eq('50')
            expect(s1.sample_metadata.gender).to eq('Female')
          end

          it 'will not update the aliquots if aliquots data has changed and override is set false' do
            download.worksheet.axlsx_worksheet.rows[10].cells[6].value = '50'
            download.worksheet.axlsx_worksheet.rows[10].cells[7].value = 'Female'
            download.save(new_test_file_name)
            reupload = SampleManifestExcel::Upload::Base.new(file: new_test_file, column_list: plate_columns, start_row: 9)
            processor = SampleManifestExcel::Upload::Processor::Plate.new(reupload)
            processor.update_samples(nil)
            expect(reupload.rows).not_to be_all(&:sample_updated?)
            s1 = Sample.find_by(sanger_sample_id: download.worksheet.axlsx_worksheet.rows[10].cells[2].value)
            expect(s1.sample_metadata.concentration).to eq('1')
            expect(s1.sample_metadata.gender).to eq('Unknown')
          end
        end
      end

      context 'invalid' do
        context 'when using foreign barcodes' do
          let(:download) { build(:test_download_plates_cgap, columns: plate_columns, validation_errors: [:sample_plate_id_duplicates]) }

          it 'duplicates will not be valid' do
            expect(processor).not_to be_valid
          end
        end
      end
    end
  end
end
