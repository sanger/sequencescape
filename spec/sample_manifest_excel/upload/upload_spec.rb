# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SampleManifestExcel::Upload, type: :model, sample_manifest_excel: true, sample_manifest: true do
  before(:all) do
    SampleManifestExcel.configure do |config|
      config.folder = File.join('spec', 'data', 'sample_manifest_excel')
      config.load!
    end
  end

  let(:user) { create :user, login: 'test_user' }
  let(:test_file_name) { 'test_file.xlsx' }
  let(:test_file) { Rack::Test::UploadedFile.new(Rails.root.join(test_file_name), '') }
  let!(:tag_group) { create(:tag_group) }
  let(:columns) { SampleManifestExcel.configuration.columns.tube_library_with_tag_sequences.dup }

  after(:all) do
    SampleManifestExcel.reset!
  end

  after do
    File.delete(test_file_name) if File.exist?(test_file_name)
  end

  it 'is valid if all of the headings relate to a column' do
    download = build(:test_download_tubes, columns: SampleManifestExcel.configuration.columns.tube_library_with_tag_sequences.dup)
    download.save(test_file_name)
    upload = SampleManifestExcel::Upload::Base.new(file: test_file, column_list: columns, start_row: 9)
    expect(upload.columns.count).to eq(columns.count)
    expect(upload).to be_valid
  end

  it 'is invalid if any of the headings do not relate to a column' do
    download = build(:test_download_tubes, columns: SampleManifestExcel.configuration.columns.tube_library_with_tag_sequences.dup.with(:my_dodgy_column))
    download.save(test_file_name)
    upload = SampleManifestExcel::Upload::Base.new(file: test_file, column_list: columns, start_row: 9)
    expect(upload).not_to be_valid
    expect(upload.errors.full_messages.to_s).to include(upload.columns.bad_keys.first)
  end

  it 'is invalid if there is no sanger sample id column' do
    download = build(:test_download_tubes, columns: SampleManifestExcel.configuration.columns.tube_library_with_tag_sequences.dup.except(:sanger_sample_id))
    download.save(test_file_name)
    upload = SampleManifestExcel::Upload::Base.new(file: test_file, column_list: columns, start_row: 9)
    expect(upload).not_to be_valid
  end

  it 'is not valid unless all of the rows are valid - library_type' do
    download = build(:test_download_tubes, columns: SampleManifestExcel.configuration.columns.tube_library_with_tag_sequences.dup, validation_errors: [:library_type])
    download.save(test_file_name)
    upload = SampleManifestExcel::Upload::Base.new(file: test_file, column_list: columns, start_row: 9)
    expect(upload).not_to be_valid
  end

  it 'is not valid unless all of the rows are valid - insert-size' do
    download = build(:test_download_tubes, columns: SampleManifestExcel.configuration.columns.tube_library_with_tag_sequences.dup, validation_errors: [:insert_size_from])
    download.save(test_file_name)
    upload = SampleManifestExcel::Upload::Base.new(file: test_file, column_list: columns, start_row: 9)
    expect(upload).not_to be_valid
  end

  it 'is not valid unless there is an associated sample manifest' do
    download = build(:test_download_tubes, columns: SampleManifestExcel.configuration.columns.tube_library_with_tag_sequences.dup, validation_errors: [:sample_manifest])
    download.save(test_file_name)

    upload = SampleManifestExcel::Upload::Base.new(file: test_file, column_list: columns, start_row: 9)
    expect(upload).not_to be_valid
  end

  it 'when completed changes sample manifest status to completed' do
    download = build(:test_download_tubes, columns: SampleManifestExcel.configuration.columns.tube_library_with_tag_sequences.dup)
    download.save(test_file_name)
    upload = SampleManifestExcel::Upload::Base.new(file: test_file, column_list: columns, start_row: 9)
    expect(upload.sample_manifest.state).to eq 'pending'
    upload.process(tag_group)
    upload.complete
    expect(upload.sample_manifest.state).to eq 'completed'
  end

  it 'knows how to create sample_manifest.updated broadcast event - tubes' do
    download = build(:test_download_tubes, columns: SampleManifestExcel.configuration.columns.tube_library_with_tag_sequences.dup)
    download.save(test_file_name)
    upload = SampleManifestExcel::Upload::Base.new(file: test_file, column_list: columns, start_row: 9)
    upload.rows.each { |row| expect(row).to receive(:changed?).at_least(:once).and_return(true) }
    expect { upload.broadcast_sample_manifest_updated_event(user) }.to change(BroadcastEvent, :count).by(1)
    # subjects are 1 study, 6 tubes and 6 samples
    expect(BroadcastEvent.first.subjects.count).to eq 13
  end

  it 'knows how to create sample_manifest.updated broadcast event - mx libraries' do
    download = build(:test_download_tubes,
                     columns: SampleManifestExcel.configuration.columns.tube_multiplexed_library_with_tag_sequences.dup,
                     manifest_type: 'tube_multiplexed_library_with_tag_sequences')
    download.save(test_file_name)
    upload = SampleManifestExcel::Upload::Base.new(
      file: test_file,
      column_list: SampleManifestExcel.configuration.columns.tube_multiplexed_library_with_tag_sequences.dup,
      start_row: 9
    )
    upload.rows.each { |row| expect(row).to receive(:changed?).at_least(:once).and_return(true) }
    expect { upload.broadcast_sample_manifest_updated_event(user) }.to change(BroadcastEvent, :count).by(1)
    # subjects are 1 study, 1 tubes and 6 samples
    expect(BroadcastEvent.last.subjects.count).to eq 8
  end

  describe '#processor' do
    context '1dtube' do
      let!(:columns) { SampleManifestExcel.configuration.columns.tube_full.dup }
      let!(:download) { build(:test_download_tubes, columns: columns) }

      before do
        download.save(test_file_name)
      end

      it 'has the correct processor' do
        upload = SampleManifestExcel::Upload::Base.new(file: test_file, column_list: columns, start_row: 9)
        expect(upload.processor).not_to be_nil
        expect(upload.processor).to be_one_d_tube
      end

      it 'updates all of the data' do
        upload = SampleManifestExcel::Upload::Base.new(file: test_file, column_list: columns, start_row: 9)
        upload.process(tag_group)
        expect(upload).to be_processed
      end
    end

    context 'saphyr' do
      let!(:columns) { SampleManifestExcel.configuration.columns.saphyr.dup }
      let!(:download) { build(:test_download_tubes, columns: columns, manifest_type: 'saphyr') }

      before do
        download.save(test_file_name)
      end

      it 'has the correct processor' do
        upload = SampleManifestExcel::Upload::Base.new(file: test_file, column_list: columns, start_row: 9)
        expect(upload.processor).not_to be_nil
        expect(upload.processor).to be_one_d_tube
      end

      it 'updates all of the data' do
        upload = SampleManifestExcel::Upload::Base.new(file: test_file, column_list: columns, start_row: 9)
        upload.process(tag_group)
        expect(upload).to be_processed
      end
    end

    context 'library tube with tag sequences' do
      let!(:columns) { SampleManifestExcel.configuration.columns.tube_library_with_tag_sequences.dup }
      let!(:download) { build(:test_download_tubes, columns: columns, manifest_type: 'tube_library_with_tag_sequences') }

      before do
        download.save(test_file_name)
      end

      it 'has the correct processor' do
        upload = SampleManifestExcel::Upload::Base.new(file: test_file, column_list: columns, start_row: 9)
        expect(upload.processor).not_to be_nil
        expect(upload.processor).to be_library_tube
      end

      it 'updates all of the data' do
        upload = SampleManifestExcel::Upload::Base.new(file: test_file, column_list: columns, start_row: 9)
        upload.process(tag_group)
        expect(upload).to be_processed
      end
    end

    context 'multiplexed library tube with tag sequences' do
      let!(:tube_multiplex_library_with_tag_seq_cols) { SampleManifestExcel.configuration.columns.tube_multiplexed_library_with_tag_sequences.dup }
      let!(:download) { build(:test_download_tubes, columns: tube_multiplex_library_with_tag_seq_cols, manifest_type: 'tube_multiplexed_library_with_tag_sequences') }

      before do
        download.save(test_file_name)
      end

      it 'has the correct processor' do
        download = build(:test_download_tubes, columns: tube_multiplex_library_with_tag_seq_cols, manifest_type: 'tube_multiplexed_library_with_tag_sequences')
        download.save(test_file_name)
        upload = SampleManifestExcel::Upload::Base.new(file: test_file, column_list: tube_multiplex_library_with_tag_seq_cols, start_row: 9)
        expect(upload.processor).not_to be_nil
        expect(upload.processor).to be_multiplexed_library_tube
      end

      it 'updates all of the data' do
        download = build(:test_download_tubes, columns: tube_multiplex_library_with_tag_seq_cols, manifest_type: 'tube_multiplexed_library_with_tag_sequences')
        download.save(test_file_name)
        upload = SampleManifestExcel::Upload::Base.new(file: test_file, column_list: tube_multiplex_library_with_tag_seq_cols, start_row: 9)
        upload.process(tag_group)
        expect(upload).to be_processed
      end

      it 'fails if tags are duplicated' do
        download = build(:test_download_tubes, columns: tube_multiplex_library_with_tag_seq_cols, manifest_type: 'tube_multiplexed_library_with_tag_sequences', validation_errors: [:tags])
        download.save(test_file_name)
        upload = SampleManifestExcel::Upload::Base.new(file: test_file, column_list: tube_multiplex_library_with_tag_seq_cols, start_row: 9)
        upload.process(tag_group)
        expect(upload).not_to be_processed
      end
    end

    context 'multiplexed library tube with tag groups and indexes' do
      let!(:multiplex_library_with_tag_grp_cols) { SampleManifestExcel.configuration.columns.tube_multiplexed_library.dup }
      let!(:download) { build(:test_download_tubes, columns: multiplex_library_with_tag_grp_cols, manifest_type: 'tube_multiplexed_library') }

      before do
        download.save(test_file_name)
      end

      it 'has the correct processor' do
        download = build(:test_download_tubes, columns: multiplex_library_with_tag_grp_cols, manifest_type: 'tube_multiplexed_library')
        download.save(test_file_name)
        upload = SampleManifestExcel::Upload::Base.new(file: test_file, column_list: multiplex_library_with_tag_grp_cols, start_row: 9)
        expect(upload.processor).not_to be_nil
        expect(upload.processor).to be_multiplexed_library_tube
      end

      it 'updates all of the data' do
        download = build(:test_download_tubes, columns: multiplex_library_with_tag_grp_cols, manifest_type: 'tube_multiplexed_library')
        download.save(test_file_name)
        upload = SampleManifestExcel::Upload::Base.new(file: test_file, column_list: multiplex_library_with_tag_grp_cols, start_row: 9)
        upload.process(tag_group)
        expect(upload).to be_processed
      end

      it 'fails if tags are duplicated' do
        download = build(:test_download_tubes, columns: multiplex_library_with_tag_grp_cols, manifest_type: 'tube_multiplexed_library', validation_errors: [:tags])
        download.save(test_file_name)
        upload = SampleManifestExcel::Upload::Base.new(file: test_file, column_list: multiplex_library_with_tag_grp_cols, start_row: 9)
        upload.process(tag_group)
        expect(upload).not_to be_processed
      end
    end

    context 'plate' do
      let!(:plate_columns) { SampleManifestExcel.configuration.columns.plate_full.dup }
      let!(:download) { build(:test_download_plates, columns: plate_columns) }

      before do
        download.save(test_file_name)
      end

      it 'has the correct processor' do
        upload = SampleManifestExcel::Upload::Base.new(file: test_file, column_list: plate_columns, start_row: 9)
        expect(upload.processor).not_to be_nil
        expect(upload.processor).to be_plate
      end

      it 'updates all of the data' do
        upload = SampleManifestExcel::Upload::Base.new(file: test_file, column_list: plate_columns, start_row: 9)
        upload.process(nil)
        expect(upload).to be_processed
      end
    end
  end
end
