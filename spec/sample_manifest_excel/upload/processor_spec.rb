# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SampleManifestExcel::Upload::Processor, type: :model do
  include SequencescapeExcel::Helpers
  include RetentionInstructionHelper

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
    let(:column_list) { configuration.columns.send(manifest_type) }

    let(:upload) { SampleManifestExcel::Upload::Base.new(file: test_file, column_list: column_list, start_row: 9) }
    let(:processor) { described_class.new(upload) }
    let(:test_file_name) { 'test_file.xlsx' }
    let(:new_test_file_name) { 'new_test_file.xlsx' }
    let(:test_file) { Rack::Test::UploadedFile.new(Rails.root.join(test_file_name), '') }
    let(:tag_group) { create(:tag_group) }

    before do
      allow(PlateBarcode).to receive(:create_barcode).and_return(build(:plate_barcode))
      download.save(test_file_name)
    end

    after { File.delete(test_file_name) if File.exist?(test_file_name) }

    shared_examples 'it updates downstream aliquots' do |rows, columns|
      it 'will update the aliquots downstream if aliquots data has changed and override is set to true' do
        cell(rows.first, columns[:insert_size_from]).value = '100'
        cell(rows.last, columns[:insert_size_to]).value = '1000'
        download.save(new_test_file_name)
        reupload2 =
          SampleManifestExcel::Upload::Base.new(
            file: new_test_file,
            column_list: column_list,
            start_row: 9,
            override: true
          )
        processor = described_class.new(reupload2)
        processor.update_samples_and_aliquots(tag_group)
        expect(processor.substitutions[0]).to include('insert_size_from' => 100)
        expect(processor.substitutions[1]).to include('insert_size_to' => 1000)
        expect(processor).to be_downstream_aliquots_updated
      end

      it 'will update the aliquots downstream if tags were swapped and override is set to true' do
        i7_tag1 = cell(rows.first, columns[:i7]).value
        i7_tag2 = cell(rows.last, columns[:i7]).value
        cell(rows.first, columns[:i7]).value = i7_tag2
        cell(rows.last, columns[:i7]).value = i7_tag1
        download.save(new_test_file_name)
        reupload2 =
          SampleManifestExcel::Upload::Base.new(
            file: new_test_file,
            column_list: column_list,
            start_row: 9,
            override: true
          )
        processor = described_class.new(reupload2)
        processor.update_samples_and_aliquots(tag_group)
        expect(processor).to be_downstream_aliquots_updated
      end

      # rubocop:todo Layout/LineLength
      it 'will update the aliquots downstream in dual index cases where the substituted tags alone look like a tag clash' do
        # rubocop:enable Layout/LineLength
        # We already have distinct tag2s, so by setting these to the same, we aren't creating a tag clash.
        cell(rows.first, columns[:i7]).value = 'ATAGATAGATAG'
        cell(rows.last, columns[:i7]).value = 'ATAGATAGATAG'
        download.save(new_test_file_name)
        reupload2 =
          SampleManifestExcel::Upload::Base.new(
            file: new_test_file,
            column_list: column_list,
            start_row: 9,
            override: true
          )
        processor = described_class.new(reupload2)
        processor.update_samples_and_aliquots(tag_group)
        expect(processor).to be_aliquots_updated
        expect(processor).to be_downstream_aliquots_updated
      end

      it 'will not update the aliquots downstream if there is nothing to update' do
        download.save(new_test_file_name)
        reupload2 =
          SampleManifestExcel::Upload::Base.new(
            file: new_test_file,
            column_list: column_list,
            start_row: 9,
            override: true
          )
        processor = described_class.new(reupload2)
        processor.update_samples_and_aliquots(tag_group)
        expect(processor.substitutions.compact).to be_empty
        expect(processor).not_to be_downstream_aliquots_updated
      end
    end

    shared_examples 'it updates chromium aliquots' do |rows, columns|
      it 'will update the aliquots downstream if aliquots data has changed and override is set to true' do
        cell(rows.first, columns[:insert_size_from]).value = '100'
        cell(rows.last, columns[:insert_size_to]).value = '1000'

        download.save(new_test_file_name)
        reupload2 =
          SampleManifestExcel::Upload::Base.new(
            file: new_test_file,
            column_list: column_list,
            start_row: 9,
            override: true
          )
        processor = described_class.new(reupload2)
        processor.update_samples_and_aliquots(tag_group)

        expect(processor.substitutions[0, 4]).to all include('insert_size_from' => 100)
        expect(processor.substitutions[4, 4]).to all include('insert_size_to' => 1000)
        expect(processor).to be_downstream_aliquots_updated
      end

      it 'will update the aliquots downstream if tags were swapped and override is set to true' do
        chromium_tag1 = cell(rows.first, columns[:chromium_tag_well]).value
        chromium_tag2 = cell(rows.last, columns[:chromium_tag_well]).value
        cell(rows.first, columns[:chromium_tag_well]).value = chromium_tag2
        cell(rows.last, columns[:chromium_tag_well]).value = chromium_tag1
        download.save(new_test_file_name)
        reupload2 =
          SampleManifestExcel::Upload::Base.new(
            file: new_test_file,
            column_list: column_list,
            start_row: 9,
            override: true
          )
        processor = described_class.new(reupload2)
        processor.update_samples_and_aliquots(tag_group)
        expect(processor.substitutions.compact.length).to eq(8)
        expect(processor).to be_downstream_aliquots_updated
      end

      # This test may seem a little paranoid, but I actually observed this behaviour
      # when testing. Somewhat lucky, as I only triggered it by accident!
      it 'will update the aliquots downstream if both tags and library types have changed' do
        new_lt = create(:library_type)
        chromium_tag1 = cell(rows.first, columns[:chromium_tag_well]).value
        chromium_tag2 = cell(rows.last, columns[:chromium_tag_well]).value
        cell(rows.first, columns[:chromium_tag_well]).value = chromium_tag2
        cell(rows.first, columns[:library_type]).value = new_lt.name
        cell(rows.last, columns[:chromium_tag_well]).value = chromium_tag1
        download.save(new_test_file_name)
        reupload2 =
          SampleManifestExcel::Upload::Base.new(
            file: new_test_file,
            column_list: column_list,
            start_row: 9,
            override: true
          )
        processor = described_class.new(reupload2)

        processor.update_samples_and_aliquots(tag_group)

        expect(processor.substitutions.compact.length).to eq(8)
        expect(processor.substitutions[0, 4]).to all include('library_type' => new_lt.name)
        expect(processor.substitutions.map(&:keys)).to all include(:original_tag_id)
        expect(processor.substitutions.map(&:keys)).to all include(:substitute_tag_id)
        expect(processor).to be_downstream_aliquots_updated
      end
    end

    describe SampleManifestExcel::Upload::Processor::OneDTube do
      let(:manifest_type) { 'tube_library_with_tag_sequences' }
      let(:download) { build(:test_download_tubes, columns: column_list, manifest_type: manifest_type) }

      context 'when valid' do
        it 'will not generate samples on initialisation' do
          expect { upload }.not_to change(Sample, :count)
        end

        it 'will not generate samples on validation' do
          expect { upload.valid? }.not_to change(Sample, :count)
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
        let(:new_test_file) { Rack::Test::UploadedFile.new(Rails.root.join(new_test_file_name), '') }

        before do
          upload.process(tag_group) || raise("Process error: #{upload.errors.full_messages}")
          upload.sample_manifest.state = 'completed'
        end

        after { File.delete(new_test_file) if File.exist?(new_test_file_name) }

        it_behaves_like 'it updates downstream aliquots', [10, 11], insert_size_from: 6, insert_size_to: 7, i7: 2

        context 'when override is true' do
          let(:override) { true }

          context 'when updating sample data' do
            let(:reupload) do
              SampleManifestExcel::Upload::Base.new(
                file: new_test_file,
                column_list: column_list,
                start_row: 9,
                override: override
              )
            end
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
          let(:reupload) do
            SampleManifestExcel::Upload::Base.new(
              file: new_test_file,
              column_list: column_list,
              start_row: 9,
              override: override
            )
          end
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

      context 'with mandatory fields' do
        let(:column_list) { configuration.columns.tube_extraction.dup }
        let(:manifest_type) { 'tube_extraction' }
        let(:download) { build(:test_download_tubes, columns: column_list, manifest_type: manifest_type) }
        let(:new_test_file) { Rack::Test::UploadedFile.new(Rails.root.join(new_test_file_name), '') }

        after { File.delete(new_test_file_name) if File.exist?(new_test_file_name) }

        shared_examples_for 'a mandatory field in the manifest' do
          it 'cannot have blank' do
            column = download.worksheet.columns.find_by(:name, mandatory_field)
            row_no = download.worksheet.first_row
            column_no = column.number
            cell(row_no - 1, column_no - 1).value = nil # zero-based index
            download.save(new_test_file_name)
            upload = SampleManifestExcel::Upload::Base.new(file: new_test_file, column_list: column_list)
            processor = described_class.new(upload)
            processor.run(nil)
            expect(processor.errors.full_messages).to include(expected_message)
          end
        end

        context 'with country of origin' do
          let(:mandatory_field) { :country_of_origin }
          let(:expected_message) { 'You must set a value for country_of_origin at row: 10' }

          it_behaves_like 'a mandatory field in the manifest'
        end

        context 'with date of sample collection' do
          let(:mandatory_field) { :date_of_sample_collection }
          let(:expected_message) { 'You must set a value for date_of_sample_collection at row: 10' }

          it_behaves_like 'a mandatory field in the manifest'
        end
      end

      context 'when using extraction tube' do
        let(:column_list) { configuration.columns.tube_extraction.dup }
        let(:manifest_type) { 'tube_extraction' }
        let(:download) { build(:test_download_tubes, columns: column_list, manifest_type: manifest_type) }
        let(:new_test_file) { Rack::Test::UploadedFile.new(Rails.root.join(new_test_file_name), '') }

        after { File.delete(new_test_file_name) if File.exist?(new_test_file_name) }

        it 'cannot have blank retention instruction' do
          column = download.worksheet.columns.find_by(:name, :retention_instruction)
          row_no = download.worksheet.first_row
          column_no = column.number
          cell(row_no - 1, column_no - 1).value = nil # zero-based index
          download.save(new_test_file_name)
          upload = SampleManifestExcel::Upload::Base.new(file: new_test_file, column_list: column_list)
          processor = described_class.new(upload)
          processor.run(nil)
          expected = "Retention instruction checks failed at row: #{row_no}. Value cannot be blank."
          expect(processor.errors.full_messages).to include(expected)
        end

        it 'must have the same retention instructions for all extraction tubes in the manifest' do
          col1 = download.worksheet.columns.find_by(:name, :retention_instruction).number - 1 # zero-based index
          row1 = download.worksheet.first_row - 1 # zero-based index
          rown = download.worksheet.last_row - 1
          (row1..rown).each { |x| cell(x, col1).value = 'Destroy after 2 years' } # Set all the same
          cell(rown, col1).value = 'Long term storage' # Set one of them different
          download.save(new_test_file_name)
          upload = SampleManifestExcel::Upload::Base.new(file: new_test_file, column_list: column_list)
          processor = described_class.new(upload)
          processor.run(nil)
          col1 = download.worksheet.columns.find_by(:name, :sanger_tube_id).number - 1
          barcode = cell(rown, col1).value
          row = rown + 1
          msg =
            "Retention instruction checks failed at row: #{row}. " \
              "Tube (#{barcode}) cannot have different retention instruction value."
          expect(processor.errors.full_messages).to include(msg)
        end
      end
    end

    describe SampleManifestExcel::Upload::Processor::LibraryTube do
      let(:download) { build(:test_download_tubes, columns: column_list, manifest_type: manifest_type) }
      let(:tag_set1) { create(:tag_set, tag_group: TagGroup.first, tag2_group: nil, name: TagGroup.first.name) }

      before { tag_set1 }

      context 'with chromium tag-columns' do
        let(:manifest_type) { 'tube_chromium_library' }

        let(:new_test_file) { Rack::Test::UploadedFile.new(Rails.root.join(new_test_file_name), '') }

        before do
          upload.process(tag_group) || raise("Process error: #{upload.errors.full_messages}")
          upload.sample_manifest.state = 'completed'
        end

        after { File.delete(new_test_file) if File.exist?(new_test_file_name) }

        it_behaves_like 'it updates chromium aliquots',
                        [10, 11],
                        insert_size_from: 7,
                        insert_size_to: 8,
                        chromium_tag_group: 3,
                        chromium_tag_well: 4,
                        library_type: 6
      end
    end

    describe SampleManifestExcel::Upload::Processor::MultiplexedLibraryTube do
      let(:manifest_type) { 'tube_multiplexed_library_with_tag_sequences' }
      let(:download) { build(:test_download_tubes, columns: column_list, manifest_type: manifest_type) }

      context 'when using tag sequences' do
        context 'when valid' do
          it 'will not generate samples on initialization' do
            expect { upload }.not_to change(Sample, :count)
          end

          it 'will not generate samples on validation' do
            expect { upload.valid? }.not_to change(Sample, :count)
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
          let(:download) { build(:test_download_tubes_partial, manifest_type: manifest_type, columns: column_list) }

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
          let(:new_test_file) { Rack::Test::UploadedFile.new(Rails.root.join(new_test_file_name), '') }

          before do
            upload.process(tag_group)
            upload.sample_manifest.state = 'completed'
          end

          after { File.delete(new_test_file_name) if File.exist?(new_test_file_name) }

          it_behaves_like 'it updates downstream aliquots', [10, 11], insert_size_from: 6, insert_size_to: 7, i7: 2
        end

        context 'with mismatched tags' do
          let(:download) do
            build(:test_download_tubes, manifest_type: manifest_type, columns: column_list, validation_errors: [:tags])
          end

          it 'will not be valid' do
            processor = described_class.new(upload)
            processor.run(tag_group)
            expect(processor).not_to be_valid
          end
        end
      end

      context 'when Multiplexed Library Tubes with Tag Groups and Indexes' do
        let(:manifest_type) { 'tube_multiplexed_library' }

        context 'when valid' do
          let(:download) { build(:test_download_tubes, manifest_type: manifest_type, columns: column_list) }

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
          let(:download) { build(:test_download_tubes_partial, manifest_type: manifest_type, columns: column_list) }

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
          let(:download) { build(:test_download_tubes, manifest_type: manifest_type, columns: column_list) }

          let(:new_test_file) { Rack::Test::UploadedFile.new(Rails.root.join(new_test_file_name), '') }

          before do
            upload.process(nil)
            upload.sample_manifest.state = 'completed'
          end

          after { File.delete(new_test_file_name) if File.exist?(new_test_file_name) }

          it 'will update the aliquots downstream if aliquots data has changed and override is set to true' do
            cell(10, 7).value = '100'
            cell(11, 8).value = '1000'
            download.save(new_test_file_name)
            reupload =
              SampleManifestExcel::Upload::Base.new(
                file: new_test_file,
                column_list: column_list,
                start_row: 9,
                override: true
              )
            processor = described_class.new(reupload)
            processor.update_samples_and_aliquots(nil)
            expect(processor.substitutions[0]).to include('insert_size_from' => 100)
            expect(processor.substitutions[1]).to include('insert_size_to' => 1000)
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
            reupload =
              SampleManifestExcel::Upload::Base.new(
                file: new_test_file,
                column_list: column_list,
                start_row: 9,
                override: true
              )
            processor = described_class.new(reupload)
            processor.update_samples_and_aliquots(nil)
            expect(processor).to be_downstream_aliquots_updated
          end

          it 'will not update the aliquots downstream if there is nothing to update' do
            download.save(new_test_file_name)
            reupload =
              SampleManifestExcel::Upload::Base.new(
                file: new_test_file,
                column_list: column_list,
                start_row: 9,
                override: true
              )
            processor = described_class.new(reupload)
            processor.update_samples_and_aliquots(nil)
            expect(processor.substitutions.compact).to be_empty
            expect(processor).not_to be_downstream_aliquots_updated
          end
        end

        context 'when tags are mismatched' do
          let(:download) do
            build(:test_download_tubes, manifest_type: manifest_type, columns: column_list, validation_errors: [:tags])
          end

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

        it 'will not generate samples on initialization' do
          expect { processor }.not_to change(Sample, :count)
        end

        it 'will not generate samples on validation' do
          expect { processor.valid? }.not_to change(Sample, :count)
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
            expect(
              upload
                .sample_manifest
                .samples
                .map do |sample|
                  sample.reload
                  sample.sample_metadata.concentration.present?
                end
                .count(true)
            ).to eq(2)
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
              expect(
                upload.sample_manifest.samples.reload.count do |sample|
                  sample.reload
                  sample.sample_metadata.concentration.present?
                end
              ).to eq(2)
              processor.update_sample_manifest
              expect(processor).to be_processed
            end
          end
        end

        context 'when manifest reuploaded and overriden' do
          let(:download) { build(:test_download_plates, columns: column_list) }

          let(:new_test_file) do
            col1 = download.worksheet.columns.find_by(:name, :concentration).number - 1
            col2 = download.worksheet.columns.find_by(:name, :gender).number - 1
            row1 = download.worksheet.first_row - 1
            cell(row1, col1).value = '50'
            cell(row1, col2).value = 'Female'
            download.save(new_test_file_name)
            Rack::Test::UploadedFile.new(Rails.root.join(new_test_file_name), '')
          end

          before do
            upload.process(nil)
            upload.sample_manifest.state = 'completed'
          end

          after { File.delete(new_test_file_name) if File.exist?(new_test_file_name) }

          it 'will update the samples if samples data has changed and override is set true' do
            reupload =
              SampleManifestExcel::Upload::Base.new(
                file: new_test_file,
                column_list: column_list,
                start_row: 9,
                override: true
              )
            processor = described_class.new(reupload)
            processor.update_samples_and_aliquots(nil)
            expect(reupload.rows).to be_all(&:sample_updated?)
            row1 = download.worksheet.first_row - 1
            col1 = download.worksheet.columns.find_by(:name, :sanger_sample_id).number - 1
            s1 = Sample.find_by(sanger_sample_id: cell(row1, col1).value)
            expect(s1.sample_metadata.concentration).to eq('50')
            expect(s1.sample_metadata.gender).to eq('Female')
          end

          it 'will not update the samples if samples data has changed and override is set false' do
            reupload =
              SampleManifestExcel::Upload::Base.new(file: new_test_file, column_list: column_list, start_row: 9)
            processor = described_class.new(reupload)
            processor.update_samples_and_aliquots(nil)
            expect(reupload.rows).not_to be_all(&:sample_updated?)
            row1 = download.worksheet.first_row - 1
            col1 = download.worksheet.columns.find_by(:name, :sanger_sample_id).number - 1
            s1 = Sample.find_by(sanger_sample_id: cell(row1, col1).value)
            expect(s1.sample_metadata.concentration).to eq('1')
            expect(s1.sample_metadata.gender).to eq('Unknown')
          end
        end
      end

      context 'when invalid' do
        context 'when using foreign barcodes' do
          let(:download) { build(:test_download_plates_cgap, columns: column_list) }

          let(:new_test_file) { Rack::Test::UploadedFile.new(Rails.root.join(new_test_file_name), '') }

          before do
            upload.process(nil)
            upload.sample_manifest.state = 'completed'
          end

          after { File.delete(new_test_file_name) if File.exist?(new_test_file_name) }

          it 'the same barcode cannot be used for multiple plates' do
            cell(9, 0).value = 'CGAP-00000'
            cell(10, 0).value = 'CGAP-00000'
            cell(11, 0).value = 'CGAP-00000'
            download.save(new_test_file_name)
            reupload =
              SampleManifestExcel::Upload::Base.new(file: new_test_file, column_list: column_list, start_row: 9)
            processor = described_class.new(reupload)
            processor.update_samples_and_aliquots(nil)
            expect(processor).not_to be_valid
          end

          it 'the same plate cannot have two different barcodes' do
            cell(9, 0).value = 'CGAP-00000'
            cell(10, 0).value = 'CGAP-11111'
            download.save(new_test_file_name)
            reupload =
              SampleManifestExcel::Upload::Base.new(file: new_test_file, column_list: column_list, start_row: 9)
            processor = described_class.new(reupload)
            processor.update_samples_and_aliquots(nil)
            expect(processor).not_to be_valid
          end
        end

        context 'when using retention instructions' do
          let(:download) { build(:test_download_plates, columns: column_list) }

          let(:new_test_file) { Rack::Test::UploadedFile.new(Rails.root.join(new_test_file_name), '') }

          before do
            upload.process(nil)
            upload.sample_manifest.state = 'completed'
          end

          after { File.delete(new_test_file_name) if File.exist?(new_test_file_name) }

          it 'the retention instructions cannot be left blank' do
            col1 = download.worksheet.columns.find_by(:name, :retention_instruction).number - 1
            row1 = download.worksheet.first_row - 1
            cell(row1, col1).value = nil
            download.save(new_test_file_name)
            reupload =
              SampleManifestExcel::Upload::Base.new(file: new_test_file, column_list: column_list, start_row: 9)
            processor = described_class.new(reupload)
            processor.update_samples_and_aliquots(nil)
            expect(processor).not_to be_valid
            expect(processor.errors.full_messages).to include(
              'Retention instruction checks failed at row: 10. Value cannot be blank.'
            )
          end

          it 'cannot have different retention instructions for the same plate' do
            col1 = download.worksheet.columns.find_by(:name, :retention_instruction).number - 1
            row1 = download.worksheet.first_row - 1
            row2 = row1 + 1
            cell(row1, col1).value = 'Destroy after 2 years'
            cell(row2, col1).value = 'Long term storage'
            download.save(new_test_file_name)
            reupload =
              SampleManifestExcel::Upload::Base.new(file: new_test_file, column_list: column_list, start_row: 9)
            processor = described_class.new(reupload)
            processor.update_samples_and_aliquots(nil)
            expect(processor).not_to be_valid
            expect(processor.errors.full_messages).to include(
              'Retention instruction checks failed at row: 11. ' \
                'Plate (SQPD-2) cannot have different retention instruction values.'
            )
          end

          it 'should populate retention_instruction attribute in labware' do
            processor.run(nil)
            expect(upload.rows).to be_all(&:sample_updated?)
            expect(upload.sample_manifest.assets.map(&:labware).map { |l| l.retention_instruction.to_sym }.uniq).to eq(
              [:long_term_storage]
            )
          end
        end
      end
    end

    describe SampleManifestExcel::Upload::Processor::TubeRack, manifest_type: 'tube_rack' do
      let(:column_list) { configuration.columns.tube_rack_default }
      let(:download) do
        build(
          :test_download_tubes_in_rack,
          columns: column_list,
          manifest_type: 'tube_rack_default',
          type: 'Tube Racks',
          count: no_of_racks,
          no_of_rows: no_of_rows - 1
        )
      end
      let(:mock_microservice_responses) do
        {
          'RK11111110' => {
            'rack_barcode' => 'RK11111110',
            'layout' => {
              'TB11111110' => 'e8',
              'TB11111111' => 'b4'
            }
          },
          'RK11111111' => {
            'rack_barcode' => 'RK11111111',
            'layout' => {
              'TB11111112' => 'a3',
              'TB11111113' => 'd6'
            }
          }
        }
      end
      let(:mock_microservices_response_status) { 200 }

      before do
        mock_microservice_responses.each_key do |rack_barcode|
          stub_request(:get, "#{configatron.tube_rack_scans_microservice_url}#{rack_barcode}").to_return(
            status: mock_microservices_response_status,
            body: JSON.generate(mock_microservice_responses[rack_barcode]),
            headers: {
            }
          )
        end
      end

      shared_examples_for 'tube rack manifest upload success case' do
        it 'will not generate samples on intitialization' do
          expect { upload }.not_to change(Sample, :count)
        end

        it 'will not generate samples on validation' do
          expect { upload.valid? }.not_to change(Sample, :count)
        end

        it 'will process', :aggregate_failures do
          expect(processor).to be_valid
          processor.run(nil)

          expect(processor.errors.messages).to be_empty

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

        it 'will generate barcodes for existing tubes' do
          # get tubes using the sample manifest asset association
          tubes = upload.sample_manifest.assets.map(&:labware)

          # sanity check the number of tubes that are present before the upload
          expect(tubes.size).to eq(no_of_rows)

          tube_ids = tubes.map(&:id)
          barcodes = Barcode.where(asset_id: tube_ids, format: 7)
          expect(barcodes).to be_empty

          processor.run(nil)

          tube_barcodes =
            mock_microservice_responses
              .values
              .first(no_of_racks)
              .map { |scan_result| scan_result['layout'].keys }
              .flatten
          tube_barcodes.reject! { |key| CsvParserClient.no_read?(key) }

          expect(barcodes.size).to eq(no_of_rows)
          expect(barcodes.map(&:barcode)).to eq(tube_barcodes)
        end

        it 'will generate tube racks, with barcodes' do
          count_before = TubeRack.count
          processor.run(nil)
          expect(TubeRack.count).to eq(count_before + no_of_racks)

          tube_rack_barcode_records = Barcode.where(barcode: mock_microservice_responses.keys, format: 'fluidx_barcode')
          expect(tube_rack_barcode_records.size).to eq(no_of_racks)
          tube_racks = TubeRack.find(tube_rack_barcode_records.map(&:asset_id))
          expect(tube_racks.compact.size).to eq(no_of_racks)
          purpose = Purpose.where(target_type: 'TubeRack', size: 48).first
          expect(purpose).not_to be_nil
          tube_racks.each do |rack|
            expect(rack.size).to eq(48)
            expect(rack.plate_purpose_id).to eq(purpose.id)
          end
        end

        it 'will generate racked tubes to link tubes to racks' do
          count_before = RackedTube.count
          processor.run(nil)
          expect(RackedTube.count).to eq(count_before + no_of_rows)

          tube_rack_barcodes = mock_microservice_responses.keys.first(no_of_racks)
          tube_rack_barcodes.each do |tube_rack_barcode|
            tube_rack = Barcode.find_by(barcode: tube_rack_barcode).asset

            layout = mock_microservice_responses[tube_rack_barcode]['layout']
            layout.each_key do |tube_barcode|
              next if CsvParserClient.no_read?(tube_barcode)

              tube = Barcode.find_by(barcode: tube_barcode).asset
              expect(tube.tube_rack).to eq(tube_rack)
              expect(tube.racked_tube.coordinate).to eq(layout[tube_barcode])
            end
          end
        end
      end

      context 'when valid with one tube rack' do
        let(:no_of_racks) { 1 }
        let(:no_of_rows) { 2 }

        it_behaves_like 'tube rack manifest upload success case'
      end

      context 'when valid with multiple tube racks' do
        let(:no_of_racks) { 2 }
        let(:no_of_rows) { 4 }

        it_behaves_like 'tube rack manifest upload success case'
      end

      context 'when the scan has \'no reads\'' do
        let(:no_of_racks) { 1 }
        let(:no_of_rows) { 1 }
        let(:mock_microservice_responses) do
          {
            'RK11111110' => {
              'rack_barcode' => 'RK11111110',
              'layout' => {
                'TB11111110' => 'e8',
                'NO READ' => 'b4'
              }
            }
          }
        end
        let(:mock_microservices_response_status) { 200 }

        it_behaves_like 'tube rack manifest upload success case'
      end

      context 'when has been previously uploaded' do
        let(:no_of_racks) { 1 }
        let(:no_of_rows) { 2 }

        before do
          tube_rack = TubeRack.create(size: 48)
          tube_rack_barcode = mock_microservice_responses.keys[0]
          Barcode.create(asset: tube_rack, barcode: tube_rack_barcode, format: 'fluidx_barcode')
          tubes = upload.sample_manifest.assets.map(&:labware)
          counter = 0
          tubes.each do |tube|
            tube_barcode = mock_microservice_responses[tube_rack_barcode]['layout'].keys[counter]
            Barcode.create(asset: tube, barcode: tube_barcode, format: 'fluidx_barcode')
            RackedTube.create(
              tube: tube,
              tube_rack: tube_rack,
              coordinate: mock_microservice_responses[tube_rack_barcode]['layout'].values[counter]
            )
            counter += 1
          end
        end

        it 'will process' do
          processor.run(nil)
          expect(processor).to be_processed
        end

        it 'will not create any data' do
          RSpec::Matchers.define_negated_matcher :not_change, :change

          expect { processor.run(nil) }.to not_change(TubeRack, :count).and not_change(
                  RackedTube,
                  :count
                ).and not_change(Barcode, :count)
        end
      end

      context 'when manifest has no tube rack barcodes' do
        let(:no_of_racks) { 0 }
        let(:no_of_rows) { 2 }

        it 'will not process' do
          processor.run(nil)
          expect(processor).not_to be_processed
        end

        it 'will not create any data' do
          RSpec::Matchers.define_negated_matcher :not_change, :change

          expect { processor.run(nil) }.to not_change(TubeRack, :count).and not_change(
                  RackedTube,
                  :count
                ).and not_change(Barcode, :count)
        end

        it 'will have errors' do
          processor.run(nil)
          errors = processor.errors.full_messages
          expect(errors).not_to be_empty
          expect(errors).to include("Tube rack barcodes from manifest can't be blank")
        end
      end

      context 'when there is no scan found for a tube rack in the manifest' do
        let(:no_of_racks) { 1 }
        let(:no_of_rows) { 2 }
        let(:mock_microservice_responses) { { 'RK11111110' => { 'error' => 'File not found' } } }
        let(:mock_microservices_response_status) { 404 }

        it 'will have errors' do
          processor.run(nil)
          errors = upload.errors.full_messages
          expect(errors).not_to be_empty
          expect(errors).to include(
            'Scan could not be retrieved for tube rack with barcode RK11111110. ' \
              'Service responded with status code 404 and the following message: File not found'
          )
        end
      end

      context 'when the microservice responds with a status of 500' do
        let(:no_of_racks) { 1 }
        let(:no_of_rows) { 2 }
        let(:mock_microservice_responses) { { 'RK11111110' => { 'error' => 'Server error' } } }
        let(:mock_microservices_response_status) { 500 }

        it 'will have errors' do
          processor.run(nil)
          errors = upload.errors.full_messages
          expect(errors).not_to be_empty
          expect(errors).to include(
            # rubocop:todo Layout/LineLength
            'Scan could not be retrieved for tube rack with barcode RK11111110. Service responded with status code 500 and the following message: Server error'
            # rubocop:enable Layout/LineLength
          )
        end
      end

      context 'when the microservice responds with an invalid body' do
        let(:no_of_racks) { 1 }
        let(:no_of_rows) { 2 }
        let(:mock_microservice_responses) { { 'RK11111110' => 'sf:fs9{8fa}afe"fas' } }
        let(:mock_microservices_response_status) { 200 }

        before do
          mock_microservice_responses.each_key do |rack_barcode|
            stub_request(:get, "#{configatron.tube_rack_scans_microservice_url}#{rack_barcode}").to_return(
              status: mock_microservices_response_status,
              body: mock_microservice_responses[rack_barcode],
              headers: {
              }
            )
          end
        end

        it 'will have errors' do
          processor.run(nil)
          errors = upload.errors.full_messages
          expect(errors).not_to be_empty
          expect(errors[0]).to start_with(
            'Response when trying to retrieve scan (tube rack with barcode RK11111110) ' \
              'was not valid JSON so could not be understood. Error message:'
          )
        end
      end

      context 'when the scan and the manifest have different tube barcodes' do
        let(:no_of_racks) { 1 }
        let(:no_of_rows) { 2 }
        let(:mock_microservice_responses) do
          { 'RK11111110' => { 'rack_barcode' => 'RK11111110', 'layout' => { 'TB22222222' => 'e8' } } }
        end
        let(:mock_microservices_response_status) { 200 }

        it 'will have errors' do
          processor.run(nil)
          errors = upload.errors.full_messages
          expect(errors).not_to be_empty
          expect(errors).to include('The scan and the manifest do not contain identical tube barcodes.')
        end
      end

      context 'when the scan has an invalid coordinate' do
        let(:no_of_racks) { 1 }
        let(:no_of_rows) { 2 }
        let(:mock_microservice_responses) do
          {
            'RK11111110' => {
              'rack_barcode' => 'RK11111110',
              'layout' => {
                'TB11111110' => 'e14',
                'TB11111111' => 'b4'
              }
            }
          }
        end
        let(:mock_microservices_response_status) { 200 }

        it 'will have errors' do
          processor.run(nil)
          errors = upload.errors.full_messages
          expect(errors).not_to be_empty
          expect(errors).to include(
            'The following coordinates in the scan are not valid for a tube rack of size 48: ["e14"].'
          )
        end

        it 'will not process' do
          processor.run(nil)
          expect(processor).not_to be_processed
        end
      end

      context 'when the tube barcode exists already' do
        let(:no_of_racks) { 1 }
        let(:no_of_rows) { 2 }
        let(:tube) { create(:tube) }

        before { Barcode.create!(asset_id: tube.id, barcode: 'TB11111110', format: 'fluidx_barcode') }

        it 'will have errors' do
          processor.run(nil)
          errors = upload.errors.full_messages
          expect(errors).not_to be_empty
          expect(errors).to include('foreign barcode is already in use.')
        end
      end
    end
  end
end
