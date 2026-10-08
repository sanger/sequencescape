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
      let(:filled_rows_by_tube) do
        rows_by_tube.select { |rows| rows.any?(&:sample) }
      end
      let(:component_tag_group) do
        handler = SequencescapeExcel::SpecialisedField::ComponentTagSequence
        create(:tag_group, name: handler::TAG_GROUP_NAME, tag_count: tag_count)
      end
      # Each filled tube holds exactly one aliquot: its compound sample's.
      let(:compound_aliquots) do
        filled_rows_by_tube.map { |rows| rows.first.asset.aliquots.sole }
      end

      before do
        component_tag_group
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

      it 'gives the component samples no aliquots' do
        expect(samples.flat_map(&:aliquots)).to be_empty
      end

      it 'puts a compound sample in each tube with components' do
        filled_tube_count = components_per_tube.count(&:positive?)
        expect(compound_aliquots.size).to eq(filled_tube_count)
      end

      it 'makes each compound sample from the component samples of its tube' do
        components = filled_rows_by_tube.map do |rows|
          rows.filter_map(&:sample).to_set
        end
        expect(compound_aliquots.map { |a| a.sample.component_samples.to_set })
          .to eq(components)
      end

      it 'stores the tags of the component samples on the compound samples' do
        tags = component_tag_group.tags.order(:map_id).to_a
        expected = components_per_tube.select(&:positive?).map do |count|
          tags.first(count).to_set
        end
        actual = compound_aliquots.map do |aliquot|
          aliquot.sample.joins_as_compound_sample.to_set(&:tag)
        end
        expect(actual).to eq(expected)
      end

      it 'sets the library type of the compound sample aliquots' do
        expect(compound_aliquots.map(&:library_type))
          .to all(eq(test_data[:library_type]))
      end

      it 'leaves the tubes without components empty' do
        blank_rows_by_tube = rows_by_tube - filled_rows_by_tube
        expect(blank_rows_by_tube.flat_map { |rows| rows.first.asset.aliquots })
          .to be_empty
      end

      it 'sets the retention instruction of the tubes with components' do
        tubes = filled_rows_by_tube.map { |rows| rows.first.asset.labware }
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

      context 'when the manifest is uploaded again' do
        let(:override_samples) { true }
        let(:reupload_file_name) { 'reupload_test_file.xlsx' }
        let(:reupload_file) do
          download.save(reupload_file_name)
          Rack::Test::UploadedFile.new(Rails.root.join(reupload_file_name), '')
        end
        let(:reuploader) do
          overrides = { samples: override_samples, exclude_fields: [] }
          described_class.new(
            reupload_file, SampleManifestExcel.configuration, user, overrides
          )
        end
        let(:tags) { component_tag_group.tags.order(:map_id).to_a }

        after { FileUtils.rm_f(reupload_file_name) }

        it 'does not create any samples' do
          expect { reuploader.run! }.not_to change(Sample, :count)
        end

        it 'processes the upload' do
          reuploader.run!
          expect(reuploader).to be_processed
        end

        it 'keeps one compound sample in each tube with components' do
          reuploader.run!
          filled_tube_count = components_per_tube.count(&:positive?)
          expect(compound_aliquots.size).to eq(filled_tube_count)
        end

        context 'without overriding the samples' do
          let(:override_samples) { false }

          it 'processes the upload' do
            reuploader.run!
            expect(reuploader).to be_processed
          end
        end

        context 'with corrected metadata for the first tube' do
          let(:library_type) { create(:library_type, name: 'Corrected type') }
          let(:compound_aliquot) { compound_aliquots.first }
          let(:reupload_file) do
            set_first_tube_values(:supplier_name, 'CORRECTED-POOL')
            set_first_tube_values(:library_type, library_type.name)
            super()
          end

          def set_first_tube_values(column_name, value)
            worksheet = download.worksheet
            index = worksheet.columns.find_by(:name, column_name).number - 1
            first_tube_rows(worksheet).each do |row|
              row.cells[index].value = value
            end
          end

          def first_tube_rows(worksheet)
            first = worksheet.first_row - 1
            rows = worksheet.axlsx_worksheet.rows
            Array.new(components_per_tube.first) { |index| rows[first + index] }
          end

          before { reuploader.run! }

          it 'processes the upload' do
            expect(reuploader).to be_processed
          end

          it 'corrects the shared metadata of the compound sample' do
            expect(compound_aliquot.sample.sample_metadata.supplier_name)
              .to eq('CORRECTED-POOL')
          end

          it 'corrects the library type of the compound sample aliquot' do
            expect(compound_aliquot.library_type).to eq(library_type.name)
          end
        end

        context 'with a changed component tag' do
          # The first row of the first tube gets a tag its tube does not use.
          let(:reupload_file) do
            worksheet = download.worksheet
            column = worksheet.columns.find_by(:name, :component_tag_sequence)
            row = worksheet.axlsx_worksheet.rows[worksheet.first_row - 1]
            row.cells[column.number - 1].value = tags.last.oligo
            super()
          end

          before { reuploader.run! }

          it 'does not process the upload' do
            expect(reuploader).not_to be_processed
          end

          it 'reports that the compound sample cannot change' do
            expect(reuploader.errors.full_messages)
              .to include(/a re-upload cannot change/)
          end

          it 'keeps the tags of the compound sample' do
            links = compound_aliquots.first.sample.joins_as_compound_sample
            first_tube_tags = tags.first(components_per_tube.first)
            expect(links.to_set(&:tag)).to eq(first_tube_tags.to_set)
          end
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
