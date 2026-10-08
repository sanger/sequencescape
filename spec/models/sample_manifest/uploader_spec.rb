# frozen_string_literal: true

require 'rails_helper'
require 'pry'

RSpec.describe SampleManifest::Uploader, :sample_manifest, :sample_manifest_excel do
  include AccessionV1ClientHelper

  before(:all) do
    SampleManifestExcel.configure do |config|
      config.folder = File.join('spec', 'data', 'sample_manifest_excel')
      config.tag_group = 'My Magic Tag Group'
      config.load!
    end
  end

  let(:test_file_name) { 'test_file.xlsx' }
  let(:test_file) { Rack::Test::UploadedFile.new(Rails.root.join(test_file_name), '') }
  let(:user) { create(:user) }

  after(:all) { SampleManifestExcel.reset! }

  after { FileUtils.rm_f(test_file_name) }

  describe '#initialize' do
    it 'will not be valid without a filename' do
      expect(described_class.new(nil, SampleManifestExcel.configuration, user, false)).not_to be_valid
    end

    it 'will not be valid without some configuration' do
      download =
        build(
          :test_download_tubes,
          manifest_type: 'tube_library_with_tag_sequences',
          columns: SampleManifestExcel.configuration.columns.tube_library_with_tag_sequences.dup
        )
      download.save(test_file_name)
      expect(described_class.new(test_file, nil, user, false)).not_to be_valid
    end

    it 'will not be valid without a tag group' do
      SampleManifestExcel.configuration.tag_group = nil
      download =
        build(
          :test_download_tubes,
          manifest_type: 'tube_library_with_tag_sequences',
          columns: SampleManifestExcel.configuration.columns.tube_library_with_tag_sequences.dup
        )
      download.save(test_file_name)
      expect(described_class.new(test_file, SampleManifestExcel.configuration, user, false)).not_to be_valid
      SampleManifestExcel.configuration.tag_group = 'My Magic Tag Group'
    end

    it 'will not be valid without a user' do
      download =
        build(
          :test_download_tubes,
          columns: SampleManifestExcel.configuration.columns.tube_library_with_tag_sequences.dup
        )
      download.save(test_file_name)
      expect(described_class.new(test_file, SampleManifestExcel.configuration, nil, false)).not_to be_valid
    end
  end

  context 'when checking uploads', :un_delay_jobs do
    before do
      create(:insdc_country, name: 'United Kingdom')
    end

    it 'will upload a valid 1d tube sample manifest' do
      broadcast_events_count = BroadcastEvent.count
      download =
        build(
          :test_download_tubes,
          manifest_type: 'tube_full',
          columns: SampleManifestExcel.configuration.columns.tube_full.dup
        )
      download.save(test_file_name)
      uploader = described_class.new(test_file, SampleManifestExcel.configuration, user, false)
      uploader.run!
      expect(uploader).to be_processed
      expect(BroadcastEvent.count).to eq broadcast_events_count + 1
      expect(uploader.upload.sample_manifest).to be_completed
    end

    it 'will upload a valid library tube with tag sequences sample manifest' do
      broadcast_events_count = BroadcastEvent.count
      download =
        build(
          :test_download_tubes,
          manifest_type: 'tube_library_with_tag_sequences',
          columns: SampleManifestExcel.configuration.columns.tube_library_with_tag_sequences.dup
        )
      download.save(test_file_name)
      uploader = described_class.new(test_file, SampleManifestExcel.configuration, user, false)
      uploader.run!
      expect(uploader).to be_processed
      expect(BroadcastEvent.count).to eq broadcast_events_count + 1
      expect(uploader.upload.sample_manifest).to be_completed
    end

    it 'will upload a valid library tube with tag sequences sample manifest with duplicated tags' do
      broadcast_events_count = BroadcastEvent.count
      download =
        build(
          :test_download_tubes,
          manifest_type: 'tube_library_with_tag_sequences',
          columns: SampleManifestExcel.configuration.columns.tube_library_with_tag_sequences.dup
        )
      download.save(test_file_name)
      uploader = described_class.new(test_file, SampleManifestExcel.configuration, user, false)
      expect { uploader.run! }.to change(Messenger, :count).by(6)
      expect(uploader).to be_processed
      expect(BroadcastEvent.count).to eq broadcast_events_count + 1
      expect(uploader.upload.sample_manifest).to be_completed
    end

    it 'will upload a valid multiplexed library tube with tag sequences sample manifest' do
      broadcast_events_count = BroadcastEvent.count
      download =
        build(
          :test_download_tubes,
          manifest_type: 'tube_multiplexed_library_with_tag_sequences',
          columns: SampleManifestExcel.configuration.columns.tube_multiplexed_library_with_tag_sequences.dup
        )
      download.save(test_file_name)
      uploader = described_class.new(test_file, SampleManifestExcel.configuration, user, false)
      uploader.run!
      expect(uploader).to be_processed
      expect(BroadcastEvent.count).to eq broadcast_events_count + 1
      expect(uploader.upload.sample_manifest).to be_completed
    end

    it 'will upload a valid multiplexed library tube with tag groups and indexes sample manifest' do
      broadcast_events_count = BroadcastEvent.count
      download =
        build(
          :test_download_tubes,
          manifest_type: 'tube_multiplexed_library',
          columns: SampleManifestExcel.configuration.columns.tube_multiplexed_library.dup
        )
      download.save(test_file_name)
      uploader = described_class.new(test_file, SampleManifestExcel.configuration, user, false)
      uploader.run!
      expect(uploader).to be_processed
      expect(BroadcastEvent.count).to eq broadcast_events_count + 1
      expect(uploader.upload.sample_manifest).to be_completed
    end

    it 'will upload a valid plate sample manifest' do
      download =
        build(
          :test_download_plates,
          manifest_type: 'plate_full',
          columns: SampleManifestExcel.configuration.columns.plate_full.dup
        )
      download.save(test_file_name)
      uploader = described_class.new(test_file, SampleManifestExcel.configuration, user, false)
      expect { uploader.run! }.to change(BroadcastEvent, :count).by(1)
      expect(uploader).to be_processed
      expect(uploader.upload.sample_manifest).to be_completed
    end

    context 'with accessioning enabled', :accessioning_enabled, :un_delay_jobs do
      before do
        allow(Accession::Submission).to receive(:client).and_return(
          stub_accession_client(:submit_and_fetch_accession_number, return_value: 'EGA00001000240')
        )
      end

      it 'will generate sample accessions' do
        number_of_plates = 2
        samples_per_plate = 2
        download =
          build(
            :test_download_plates,
            num_plates: number_of_plates,
            num_filled_wells_per_plate: samples_per_plate,
            manifest_type: 'plate_full',
            columns: SampleManifestExcel.configuration.columns.plate_full.dup,
            study: create(:open_study, accession_number: 'acc')
          )
        download.save(test_file_name)
        uploader = described_class.new(test_file, SampleManifestExcel.configuration, user, false)
        Delayed::Worker.delay_jobs = true # Delay the jobs to prevent inline running - and increase the count
        expect { uploader.run! }.to change(Delayed::Job, :count).by(number_of_plates * samples_per_plate)
      end

      it 'will update accessioned data if the samples are already accessioned' do
        download =
          build(
            :test_download_plates,
            manifest_type: 'plate_full',
            columns: SampleManifestExcel.configuration.columns.plate_full.dup,
            study: create(:open_study, accession_number: 'acc')
          )
        download.save(test_file_name)
        uploader = described_class.new(test_file, SampleManifestExcel.configuration, user, false)

        # Mock sample.sample_metadata.sample_ebi_accession_number.present? to return true
        allow_any_instance_of(Sample::Metadata) # rubocop:disable RSpec/AnyInstance
          .to receive(:sample_ebi_accession_number)
          .and_return('existing_accession_number')
        allow(Rails.logger).to receive(:info)

        # When uploading the same manifest again, re-accession using modify.
        # See spec/lib/accession/submission_spec.rb for tests with the MODIFY action.
        uploader.run!
        expect(uploader).to be_processed
        expect(uploader.upload.sample_manifest).to be_completed

        # Check for updates being logged
        expect(Rails.logger).to have_received(:info).with(
          a_string_matching(
            /^Sample 'sample_1' with .* has had it's accession metadata successfully updated\.$/
          )
        )
        expect(Rails.logger).to have_received(:info).with(
          a_string_matching(
            /^Sample 'sample_2' with .* has had it's accession metadata successfully updated\.$/
          )
        )
        expect(Rails.logger).to have_received(:info).with(
          a_string_matching(
            /^Sample 'sample_3' with .* has had it's accession metadata successfully updated\.$/
          )
        )
        expect(Rails.logger).to have_received(:info).with(
          a_string_matching(
            /^Sample 'sample_4' with .* has had it's accession metadata successfully updated\.$/
          )
        )
      end
    end

    it 'will not upload an invalid 1d tube sample manifest' do
      download =
        build(
          :test_download_tubes,
          manifest_type: 'tube_full',
          columns: SampleManifestExcel.configuration.columns.tube_full.dup,
          validation_errors: [:sanger_sample_id_invalid]
        )
      download.save(test_file_name)
      expect(described_class.new(test_file, SampleManifestExcel.configuration, user, false)).not_to be_valid
    end

    it 'will not upload an invalid library tube with tag sequences sample manifest' do
      download =
        build(
          :test_download_tubes,
          manifest_type: 'tube_library_with_tag_sequences',
          columns: SampleManifestExcel.configuration.columns.tube_library_with_tag_sequences.dup,
          validation_errors: [:sanger_sample_id_invalid]
        )
      download.save(test_file_name)
      expect(described_class.new(test_file, SampleManifestExcel.configuration, user, false)).not_to be_valid
    end

    it 'will not upload an invalid multiplexed library tube with tag sequences sample manifest' do
      download =
        build(
          :test_download_tubes,
          manifest_type: 'tube_multiplexed_library_with_tag_sequences',
          columns: SampleManifestExcel.configuration.columns.tube_multiplexed_library_with_tag_sequences.dup,
          validation_errors: [:sanger_sample_id_invalid]
        )
      download.save(test_file_name)
      expect(described_class.new(test_file, SampleManifestExcel.configuration, user, false)).not_to be_valid
    end

    it 'will not upload an invalid multiplexed library tube with tag groups and indexes sample manifest' do
      download =
        build(
          :test_download_tubes,
          manifest_type: 'tube_multiplexed_library',
          columns: SampleManifestExcel.configuration.columns.tube_multiplexed_library.dup,
          validation_errors: [:sanger_sample_id_invalid]
        )
      download.save(test_file_name)
      expect(described_class.new(test_file, SampleManifestExcel.configuration, user, false)).not_to be_valid
    end

    it 'will not upload an invalid plate sample manifest' do
      download =
        build(
          :test_download_plates,
          manifest_type: 'plate_full',
          columns: SampleManifestExcel.configuration.columns.plate_full.dup,
          validation_errors: [:sanger_sample_id_invalid]
        )
      download.save(test_file_name)
      expect(described_class.new(test_file, SampleManifestExcel.configuration, user, false)).not_to be_valid
    end

    it 'will upload a valid partial 1d tube sample manifest' do
      download =
        build(
          :test_download_tubes_partial,
          manifest_type: 'tube_full',
          columns: SampleManifestExcel.configuration.columns.tube_full.dup
        )
      download.save(test_file_name)
      uploader = described_class.new(test_file, SampleManifestExcel.configuration, user, false)
      uploader.run!
      expect(uploader).to be_processed
    end

    it 'will upload a valid partial library tube sample manifest' do
      download =
        build(
          :test_download_tubes_partial,
          manifest_type: 'tube_library_with_tag_sequences',
          columns: SampleManifestExcel.configuration.columns.tube_library_with_tag_sequences.dup
        )
      download.save(test_file_name)
      uploader = described_class.new(test_file, SampleManifestExcel.configuration, user, false)
      uploader.run!
      expect(uploader).to be_processed
    end

    it 'will upload a valid partial multiplexed library tube with tag sequences sample manifest' do
      download =
        build(
          :test_download_tubes_partial,
          manifest_type: 'tube_multiplexed_library_with_tag_sequences',
          columns: SampleManifestExcel.configuration.columns.tube_multiplexed_library_with_tag_sequences.dup
        )
      download.save(test_file_name)
      uploader = described_class.new(test_file, SampleManifestExcel.configuration, user, false)
      uploader.run!
      expect(uploader).to be_processed
    end

    it 'will upload a valid partial multiplexed library tube with tag groups and indexes' do
      download =
        build(
          :test_download_tubes_partial,
          manifest_type: 'tube_multiplexed_library',
          columns: SampleManifestExcel.configuration.columns.tube_multiplexed_library.dup
        )
      download.save(test_file_name)
      uploader = described_class.new(test_file, SampleManifestExcel.configuration, user, false)
      uploader.run!
      expect(uploader).to be_processed
    end

    # The manifest is generated for 2 plates, with 2 wells each, with 1 sample per well.
    # The test_download_plates_partial factory leaves the last 2 rows of the manifest empty.
    # So 2 samples are uploaded for the first plate, and 0 samples for the second plate.
    it 'will upload a valid partial plate sample manifest' do
      download = build(:test_download_plates_partial, columns: SampleManifestExcel.configuration.columns.plate_full.dup)
      download.save(test_file_name)
      uploader = described_class.new(test_file, SampleManifestExcel.configuration, user, false)
      uploader.run!
      expect(uploader).to be_processed
    end

    context 'with a pools plate manifest' do
      let(:uploader) { described_class.new(test_file, SampleManifestExcel.configuration, user, false) }

      before do
        # create a test manifest file with 2 plates, 2 wells per plate, and 2 rows per well
        download =
          build(
            :test_download_plates,
            num_rows_per_well: 2,
            columns: SampleManifestExcel.configuration.columns.pools_plate.dup
          )
        download.save(test_file_name)
        uploader.run!
      end

      it 'will upload the manifest' do
        expect(uploader).to be_processed
      end

      it 'will understand there is one pool per well' do
        expect(uploader.upload.sample_manifest.pools).not_to be_nil
        expect(uploader.upload.sample_manifest.pools.count).to eq(4) # one pool per well
      end

      it 'will set tag_depth on aliquots' do
        labware = uploader.upload.sample_manifest.labware
        expect(labware.count).to eq(2)

        labware.each do |plate|
          wells = plate.wells
          expect(wells.count).to eq(2)

          wells.each do |well|
            aliquots = well.aliquots

            # within a well, each aliquot should have its own tag_depth
            expect(aliquots.map(&:tag_depth).uniq.count).to eq(aliquots.count)
          end
        end
      end
    end

    context 'with a compound sample tube manifest' do
      let(:tag_count) { 8 }
      let(:components_per_tube) { [6, 6, 0] }
      let(:uploader) do
        described_class.new(
          test_file, SampleManifestExcel.configuration, user, false
        )
      end
      let(:manifest) { uploader.upload.sample_manifest }
      let(:download) do
        columns = SampleManifestExcel.configuration.columns
        build(
          :test_download_compound_tubes,
          columns: columns.kinnex_compound_sample_tube.dup,
          count: components_per_tube.size,
          components_per_tube: components_per_tube
        )
      end
      let(:test_data) { download.worksheet.data }
      let(:samples) { Sample.where(sample_manifest_id: manifest.id) }
      let(:rows_by_tube) do
        manifest.sample_manifest_assets.includes(:sample)
          .group_by(&:asset).values
      end

      before do
        handler = SequencescapeExcel::SpecialisedField::ComponentTagSequence
        create(:tag_group, name: handler::TAG_GROUP_NAME, tag_count: tag_count)
        download.save(test_file_name)
        uploader.run!
      end

      it 'processes the upload' do
        expect(uploader).to be_processed
      end

      it 'completes the manifest' do
        expect(manifest).to be_completed
      end

      it 'creates a component sample for each filled row of each tube' do
        expect(rows_by_tube.map { |rows| rows.count(&:sample) })
          .to eq(components_per_tube)
      end

      it 'stores the metadata of the component samples' do
        expect(samples.map(&:sample_metadata)).to all(
          have_attributes(
            supplier_name: test_data[:supplier_name],
            donor_id: test_data[:donor_id]
          )
        )
      end

      it 'does not put the component samples in the tubes' do
        receptacles = rows_by_tube.map { |rows| rows.first.asset }
        expect(receptacles.flat_map(&:aliquots)).to be_empty
      end

      it 'gives the component samples no aliquots' do
        expect(samples.flat_map(&:aliquots)).to be_empty
      end

      it 'sets the retention instruction of the tubes with components' do
        filled_tubes = rows_by_tube.select { |rows| rows.any?(&:sample) }
        tubes = filled_tubes.map { |rows| rows.first.asset.labware }
        expect(tubes.map(&:retention_instruction))
          .to all(eq('long_term_storage'))
      end

      context 'when a component tag sequence is not in the tag group' do
        let(:download) do
          super().tap do |test_download|
            worksheet = test_download.worksheet
            column = worksheet.columns.find_by(:name, :component_tag_sequence)
            row = worksheet.axlsx_worksheet.rows[worksheet.first_row - 1]
            row.cells[column.number - 1].value = 'ACGTACGT'
          end
        end

        it 'does not process the upload' do
          expect(uploader).not_to be_processed
        end

        it 'reports the component tag sequence error' do
          expect(uploader.errors.full_messages)
            .to include(/Component tag sequence must match a tag/)
        end
      end
    end
  end

  context 'when checking sample manifest state', :un_delay_jobs do
    before do
      create(:insdc_country, name: 'United Kingdom')
    end

    it 'will not be valid if the sample_manifest is already being processed' do
      download =
        build(
          :test_download_tubes,
          columns: SampleManifestExcel.configuration.columns.tube_library_with_tag_sequences.dup
        )
      download.save(test_file_name)
      uploader = described_class.new(test_file, SampleManifestExcel.configuration, user, false)
      # Sets the sample manifest to be processing state
      uploader.upload.sample_manifest.start!
      expect(uploader).not_to be_valid
      expect(uploader.errors.full_messages).to include(
        'A version of this sample manifest is already being processed, please wait until it has completed.'
      )
    end

    it 'will be valid if the sample_manifest is not already being processed' do
      download =
        build(
          :test_download_plates,
          manifest_type: 'plate_full',
          columns: SampleManifestExcel.configuration.columns.plate_full.dup
        )
      download.save(test_file_name)
      uploader = described_class.new(test_file, SampleManifestExcel.configuration, user, false)
      # Set it to its initial state
      uploader.upload.sample_manifest.state = 'pending'
      expect { uploader.run! }.to change(BroadcastEvent, :count).by(1)
      expect(uploader).to be_processed
      expect(uploader.upload.sample_manifest).to be_completed
    end
  end
end
