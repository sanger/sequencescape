# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SampleManifestExcel::Upload::Processor, type: :model do
  include SequencescapeExcel::Helpers

  def cell(row, column)
    download.worksheet.axlsx_worksheet.rows[row].cells[column]
  end

  attr_reader :upload

  let(:fake_upload) { Struct.new(:name, :id) }

  it 'is not valid without an upload' do
    expect(SampleManifestExcel::Upload::Processor::Base.new(fake_upload)).not_to be_valid
    expect(SampleManifestExcel::Upload::Processor::Base.new(nil)).not_to be_valid
  end

  describe '#run' do
    let(:configuration) do
      SampleManifestExcel::Configuration.new do |config|
        config.folder = File.join('spec', 'data', 'sample_manifest_excel')
        config.load!
      end
    end

    let(:upload) { SampleManifestExcel::Upload::Base.new(file: test_file, column_list: column_list, start_row: 9) }
    let(:processor) { described_class.new(upload) }
    let(:test_file_name) { 'test_file.xlsx' }
    let(:test_file) { Rack::Test::UploadedFile.new(Rails.root.join(test_file_name), '') }
    let(:tag_group) { create(:tag_group) }

    before do
      barcode = build(:plate_barcode, barcode: 23)
      allow(PlateBarcode).to receive(:create).and_return(barcode)

      download.worksheet.sample_manifest.generate
      download.save(test_file_name)
    end

    after do
      File.delete(test_file_name) if File.exist?(test_file_name)
    end

    shared_examples 'it updates downstream aliquots' do |rows, columns|
      it 'will update the aliquots downstream if aliquots data has changed and override is set to true' do
        cell(rows.first, columns[:insert_size_from]).value = '100'
        cell(rows.last, columns[:insert_size_to]).value = '1000'
        download.save(new_test_file_name)
        reupload2 = SampleManifestExcel::Upload::Base.new(file: new_test_file, column_list: column_list, start_row: 9, override: true)
        processor = described_class.new(reupload2)
        processor.update_samples_and_aliquots(tag_group)
        expect(processor.substitutions[1]).to include('insert_size_from' => 100)
        expect(processor.substitutions[2]).to include('insert_size_to' => 1000)
        expect(processor).to be_downstream_aliquots_updated
      end

      it 'will update the aliquots downstream if tags were swapped and override is set to true' do
        i7_tag1 = cell(rows.first, columns[:i7]).value
        i7_tag2 = cell(rows.last, columns[:i7]).value
        cell(rows.first, columns[:i7]).value = i7_tag2
        cell(rows.last, columns[:i7]).value = i7_tag1
        download.save(new_test_file_name)
        reupload2 = SampleManifestExcel::Upload::Base.new(file: new_test_file, column_list: column_list, start_row: 9, override: true)
        processor = described_class.new(reupload2)
        processor.update_samples_and_aliquots(tag_group)
        expect(processor).to be_downstream_aliquots_updated
      end

      it 'will update the aliquots downstream in dual index cases where the substituted tags alone look like a tag clash' do
        # We already have distinct tag2s, so by setting these to the same, we aren't creating a tag clash.
        cell(rows.first, columns[:i7]).value = 'ATAGATAGATAG'
        cell(rows.last, columns[:i7]).value = 'ATAGATAGATAG'
        download.save(new_test_file_name)
        reupload2 = SampleManifestExcel::Upload::Base.new(file: new_test_file, column_list: column_list, start_row: 9, override: true)
        processor = described_class.new(reupload2)
        processor.update_samples_and_aliquots(tag_group)
        expect(processor).to be_aliquots_updated
        expect(processor).to be_downstream_aliquots_updated
      end

      it 'will not update the aliquots downstream if there is nothing to update' do
        download.save(new_test_file_name)
        reupload2 = SampleManifestExcel::Upload::Base.new(file: new_test_file, column_list: column_list, start_row: 9, override: true)
        processor = described_class.new(reupload2)
        processor.update_samples_and_aliquots(tag_group)
        expect(processor.substitutions.compact).to be_empty
        expect(processor).not_to be_downstream_aliquots_updated
      end
    end

    describe SampleManifestExcel::Upload::Processor::OneDTube do
      let(:column_list) { configuration.columns.tube_library_with_tag_sequences }

      context 'when valid' do
        let(:download) { build(:test_download_tubes, columns: column_list, manifest_type: 'tube_library_with_tag_sequences') }

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

      context 'when the manifest is re-uploaded and overridden' do
        let(:download) { build(:test_download_tubes, columns: column_list, manifest_type: 'tube_library_with_tag_sequences') }
        let(:new_test_file_name) { 'new_test_file.xlsx' }
        let(:new_test_file) { Rack::Test::UploadedFile.new(Rails.root.join(new_test_file_name), '') }

        before do
          upload.process(tag_group) || raise("Process error: #{upload.errors.full_messages}")
          upload.complete
        end

        after do
          File.delete(new_test_file) if File.exist?(new_test_file_name)
        end

        it_behaves_like 'it updates downstream aliquots', [10, 11], insert_size_from: 6, insert_size_to: 7, i7: 2

        context 'when override is true' do
          let(:override) { true }

          context 'when updating sample data' do
            let(:reupload) { SampleManifestExcel::Upload::Base.new(file: new_test_file, column_list: column_list, start_row: 9, override: override) }
            let(:processor) { described_class.new(reupload) }

            before do
              cell(10, 11).value = '50'
              cell(10, 12).value = 'Female'
              download.save(new_test_file_name)

              processor.update_samples_and_aliquots(tag_group)
            end

            it 'will update the samples if sample data has changed' do
              expect(reupload.rows).to be_all(&:sample_updated?)
              s1 = Sample.find_by(sanger_sample_id: cell(10, 1).value)
              expect(s1.sample_metadata.concentration).to eq('50')
              expect(s1.sample_metadata.gender).to eq('Female')
            end
          end
        end

        context 'when override is false' do
          let(:override) { false }
          let(:reupload) { SampleManifestExcel::Upload::Base.new(file: new_test_file, column_list: column_list, start_row: 9, override: override) }
          let(:processor) { described_class.new(reupload) }

          before do
            cell(10, 11).value = '50'
            cell(10, 12).value = 'Female'
            download.save(new_test_file_name)

            processor.update_samples_and_aliquots(tag_group)
          end

          it 'will not update the samples if sample data has changed' do
            expect(reupload.rows).not_to be_all(&:sample_updated?)
            s1 = Sample.find_by(sanger_sample_id: cell(10, 1).value)
            expect(s1.sample_metadata.concentration).to eq('1')
            expect(s1.sample_metadata.gender).to eq('Unknown')
          end
        end
      end
    end

    describe SampleManifestExcel::Upload::Processor::MultiplexedLibraryTube do
      context 'when using tag sequences' do
        let(:column_list) { configuration.columns.tube_multiplexed_library_with_tag_sequences }

        context 'when valid' do
          let(:download) { build(:test_download_tubes, manifest_type: 'tube_multiplexed_library_with_tag_sequences', columns: column_list) }

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

        context 'with a partial manifest' do
          let(:download) { build(:test_download_tubes_partial, manifest_type: 'tube_multiplexed_library_with_tag_sequences', columns: column_list) }

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

        context 'when manifest re-uploaded and overridden' do
          let(:download) { build(:test_download_tubes, manifest_type: 'tube_multiplexed_library_with_tag_sequences', columns: column_list) }
          let(:new_test_file_name) { 'new_test_file.xlsx' }
          let(:new_test_file) { Rack::Test::UploadedFile.new(Rails.root.join(new_test_file_name), '') }

          before do
            upload.process(tag_group)
            upload.complete
          end

          after do
            File.delete(new_test_file_name) if File.exist?(new_test_file_name)
          end

          it_behaves_like 'it updates downstream aliquots', [10, 11], insert_size_from: 6, insert_size_to: 7, i7: 2
        end

        context 'with mismatched tags' do
          let(:download) { build(:test_download_tubes, manifest_type: 'tube_multiplexed_library_with_tag_sequences', columns: column_list, validation_errors: [:tags]) }

          it 'will not be valid' do
            processor = described_class.new(upload)
            processor.run(tag_group)
            expect(processor).not_to be_valid
          end
        end
      end

      context 'when Multiplexed Library Tubes with Tag Groups and Indexes' do
        let(:column_list) { configuration.columns.tube_multiplexed_library }

        context 'when valid' do
          let(:download) { build(:test_download_tubes, manifest_type: 'tube_multiplexed_library', columns: column_list) }

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

        context 'when partially filled in' do
          let(:download) { build(:test_download_tubes_partial, manifest_type: 'tube_multiplexed_library', columns: column_list) }

          it 'will process partial upload and cancel unprocessed requests' do
            processor = described_class.new(upload)
            expect(upload.sample_manifest.pending_external_library_creation_requests.count).to eq 6
            processor.update_samples_and_aliquots(nil)
            expect(upload.sample_manifest.pending_external_library_creation_requests.count).to eq 2
            processor.cancel_unprocessed_external_library_creation_requests
            expect(upload.sample_manifest.pending_external_library_creation_requests.count).to eq 0
            processor.update_sample_manifest
            expect(processor).to be_processed
          end
        end

        context 'when manifest is reuploaded and overriden' do
          let(:download) { build(:test_download_tubes, manifest_type: 'tube_multiplexed_library', columns: column_list) }
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
            cell(10, 7).value = '100'
            cell(11, 8).value = '1000'
            download.save(new_test_file_name)
            reupload = SampleManifestExcel::Upload::Base.new(file: new_test_file, column_list: column_list, start_row: 9, override: true)
            processor = described_class.new(reupload)
            processor.update_samples_and_aliquots(nil)
            expect(processor.substitutions[1]).to include('insert_size_from' => 100)
            expect(processor.substitutions[2]).to include('insert_size_to' => 1000)
            expect(processor).to be_downstream_aliquots_updated
          end

          it 'will update the aliquots downstream if tag indexes were swapped and override is set to true' do
            tag_group1 = cell(10, 2).value
            tag_index1 = cell(10, 3).value
            tag_group2 = cell(11, 2).value
            tag_index2 = cell(11, 3).value
            cell(10, 2).value = tag_group2
            cell(10, 3).value = tag_index2
            cell(11, 2).value = tag_group1
            cell(11, 3).value = tag_index1
            download.save(new_test_file_name)
            reupload = SampleManifestExcel::Upload::Base.new(file: new_test_file, column_list: column_list, start_row: 9, override: true)
            processor = described_class.new(reupload)
            processor.update_samples_and_aliquots(nil)
            expect(processor).to be_downstream_aliquots_updated
          end

          it 'will not update the aliquots downstream if there is nothing to update' do
            download.save(new_test_file_name)
            reupload = SampleManifestExcel::Upload::Base.new(file: new_test_file, column_list: column_list, start_row: 9, override: true)
            processor = described_class.new(reupload)
            processor.update_samples_and_aliquots(nil)
            expect(processor.substitutions.compact).to be_empty
            expect(processor).not_to be_downstream_aliquots_updated
          end
        end

        context 'when tags are mismatched' do
          let(:download) { build(:test_download_tubes, manifest_type: 'tube_multiplexed_library', columns: column_list, validation_errors: [:tags]) }

          it 'will not be valid' do
            processor = described_class.new(upload)
            processor.run(nil)
            expect(processor).not_to be_valid
          end
        end
      end
    end

    describe SampleManifestExcel::Upload::Processor::Plate do
      let(:column_list) { configuration.columns.plate_default.dup }

      context 'when valid' do
        let(:download) { build(:test_download_plates, columns: column_list) }

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

        context 'when partial' do
          let(:download) { build(:test_download_plates_partial, columns: column_list) }

          it 'will process a partial upload' do
            processor.update_samples_and_aliquots(nil)
            expect(upload.sample_manifest.samples.map do |sample|
              sample.reload
              sample.sample_metadata.concentration.present?
            end.count(true)).to eq(2)
            processor.update_sample_manifest
            expect(processor).to be_processed
          end
        end

        context 'when using foreign barcodes' do
          let(:download) { build(:test_download_plates_cgap, columns: column_list) }

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

          context 'with a partial manifest' do
            let(:download) { build(:test_download_plates_partial_cgap, columns: column_list) }

            it 'will process a partial upload' do
              processor.update_samples_and_aliquots(nil)
              expect(upload.sample_manifest.samples.reload.count do |sample|
                sample.reload
                sample.sample_metadata.concentration.present?
              end).to eq(2)
              processor.update_sample_manifest
              expect(processor).to be_processed
            end
          end
        end

        context 'when manifest reuploaded and overriden' do
          let(:download) { build(:test_download_plates, columns: column_list) }
          let(:new_test_file_name) { 'new_test_file.xlsx' }
          let(:new_test_file) do
            cell(10, 6).value = '50'
            cell(10, 7).value = 'Female'
            download.save(new_test_file_name)
            Rack::Test::UploadedFile.new(Rails.root.join(new_test_file_name), '')
          end

          before do
            upload.process(nil)
            upload.complete
          end

          after do
            File.delete(new_test_file_name) if File.exist?(new_test_file_name)
          end

          it 'will update the samples if samples data has changed and override is set true' do
            reupload = SampleManifestExcel::Upload::Base.new(file: new_test_file, column_list: column_list, start_row: 9, override: true)
            processor = described_class.new(reupload)
            processor.update_samples_and_aliquots(nil)
            expect(reupload.rows).to be_all(&:sample_updated?)
            s1 = Sample.find_by(sanger_sample_id: cell(10, 2).value)
            expect(s1.sample_metadata.concentration).to eq('50')
            expect(s1.sample_metadata.gender).to eq('Female')
          end

          it 'will not update the samples if samples data has changed and override is set false' do
            reupload = SampleManifestExcel::Upload::Base.new(file: new_test_file, column_list: column_list, start_row: 9)
            processor = described_class.new(reupload)
            processor.update_samples_and_aliquots(nil)
            expect(reupload.rows).not_to be_all(&:sample_updated?)
            s1 = Sample.find_by(sanger_sample_id: cell(10, 2).value)
            expect(s1.sample_metadata.concentration).to eq('1')
            expect(s1.sample_metadata.gender).to eq('Unknown')
          end
        end
      end

      context 'when invalid' do
        context 'when using foreign barcodes' do
          let(:download) { build(:test_download_plates_cgap, columns: column_list) }
          let(:new_test_file_name) { 'new_test_file.xlsx' }
          let(:new_test_file) { Rack::Test::UploadedFile.new(Rails.root.join(new_test_file_name), '') }

          before do
            upload.process(nil)
            upload.complete
          end

          after do
            File.delete(new_test_file_name) if File.exist?(new_test_file_name)
          end

          it 'the same barcode cannot be used for multiple plates' do
            cell(9, 0).value = 'CGAP-00000'
            cell(10, 0).value = 'CGAP-00000'
            cell(11, 0).value = 'CGAP-00000'
            download.save(new_test_file_name)
            reupload = SampleManifestExcel::Upload::Base.new(file: new_test_file, column_list: column_list, start_row: 9)
            processor = described_class.new(reupload)
            processor.update_samples_and_aliquots(nil)
            expect(processor).not_to be_valid
          end

          it 'the same plate cannot have two different barcodes' do
            cell(9, 0).value = 'CGAP-00000'
            cell(10, 0).value = 'CGAP-11111'
            download.save(new_test_file_name)
            reupload = SampleManifestExcel::Upload::Base.new(file: new_test_file, column_list: column_list, start_row: 9)
            processor = described_class.new(reupload)
            processor.update_samples_and_aliquots(nil)
            expect(processor).not_to be_valid
          end
        end
      end
    end

    describe SampleManifestExcel::Upload::Processor::TubeRack do
      let(:column_list) { configuration.columns.tube_rack_default }

      context 'when valid with one tube rack' do
        let(:download) { build(:test_download_tubes_in_rack, columns: column_list, manifest_type: 'tube_rack_default', type: 'Tube Racks', count: 1, no_of_rows: 1) }

        it 'will not generate samples prior to processing' do
          expect { upload }.not_to change(Sample, :count)
        end

        it 'will process', :aggregate_failures do
          expect(processor).to be_valid
          puts "*** processor errors: #{processor.errors.full_messages}"
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
          puts "*** errors: #{upload.errors.full_messages}"
        end

        # it 'will generate tube racks, with barcodes' do

        # end

        # it 'will generate racked tubes to link tubes to racks' do

        # end

        # it 'will generate barcodes for existing tubes' do

        # end
      end

      context 'when valid with multiple tube racks' do
        let(:download) { build(:test_download_tubes_in_rack, columns: column_list, manifest_type: 'tube_rack_default', type: 'Tube Racks', count: 2, no_of_rows: 3) }

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

        # it 'will generate tube racks, with barcodes' do

        # end

        # it 'will generate racked tubes to link tubes to racks' do

        # end

        # it 'will generate barcodes for existing tubes' do

        # end
      end
    end
  end
end
