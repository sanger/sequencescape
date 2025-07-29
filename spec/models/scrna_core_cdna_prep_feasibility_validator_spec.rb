# frozen_string_literal: true

require 'rails_helper'

# This spec tests the Submission::ScrnaCoreCdnaPrepFeasibilityValidator module
# included by the BulkSubmission class through the ValidationsByTemplateName
# module. CSV files are created for bulk submissions and the validations
# provided by the module are tested.
RSpec.describe BulkSubmission, with: :uploader do
  # Enable the feature flag for the feasibility validations.
  # The test subject is initialised with the uploaded file.
  subject(:bulk_submission) { described_class.new(spreadsheet: submission_file) }

  before do
    SubmissionSerializer.construct!(submission_template_hash) # Create the template.
  end

  # The CSV headers are used to create the CSV content; copied from headings in
  # config/bulk_submission_excel/columns.yml
  let(:csv_headers) do
    [
      'User Login',
      'Template Name',
      'Project Name',
      'Study Name',
      'Submission name',
      'Barcode',
      'Plate Well',
      'Asset Group Name',
      'Fragment Size From',
      'Fragment Size To',
      'PCR Cycles',
      'Library Type',
      'Bait Library Name',
      'Pre-capture Plex Level',
      'Pre-capture Group',
      'Read Length',
      'Number of lanes',
      'Priority',
      'Primer Panel',
      'Comments',
      'Gigabases Expected',
      'Flowcell Type',
      'scRNA Core Number of Pools',
      'scRNA Core Cells per Chip Well'
    ]
  end
  # Three study-project groups with different number of samples.
  # Note that setting a positive number of samples for a study-project group
  # will enable it for a test in a context; setting it to zero will disable it.
  let(:group_1_number_of_samples) { 15 } # Study 1, Project 1
  let(:group_2_number_of_samples) { 15 }
  let(:group_3_number_of_samples) { 15 }
  # The number of pools for each study-project group.
  let(:group_1_number_of_pools) { 1 }
  let(:group_2_number_of_pools) { 1 }
  let(:group_3_number_of_pools) { 1 }
  # The cells per chip well for each study-project group.
  let(:group_1_cells_per_chip_well) { 90_000 }
  let(:group_2_cells_per_chip_well) { 90_000 }
  let(:group_3_cells_per_chip_well) { 90_000 }
  # Donor IDs for each group to set on the samples.
  let(:group_1_donors) { Array.new(group_1_number_of_samples) { |index| "group_1_donor_#{index + 1}" } }
  let(:group_2_donors) { Array.new(group_2_number_of_samples) { |index| "group_2_donor_#{index + 1}" } }
  let(:group_3_donors) { Array.new(group_3_number_of_samples) { |index| "group_3_donor_#{index + 1}" } }
  # Tubes for each group with sample_metadata that contains the donor ID.
  let(:group_1_tubes) do
    Array.new(group_1_number_of_samples) do |index|
      create(:sample_tube).tap { |tube| tube.samples.first.sample_metadata.update!(donor_id: group_1_donors[index]) }
    end
  end
  let(:group_2_tubes) do
    Array.new(group_2_number_of_samples) do |index|
      create(:sample_tube).tap { |tube| tube.samples.first.sample_metadata.update!(donor_id: group_2_donors[index]) }
    end
  end
  let(:group_3_tubes) do
    Array.new(group_3_number_of_samples) do |index|
      create(:sample_tube).tap { |tube| tube.samples.first.sample_metadata.update!(donor_id: group_3_donors[index]) }
    end
  end
  # CSV rows for each group with the specified values.
  let(:group_1_rows) do
    Array.new(group_1_number_of_samples) do |index|
      new_csv_row(
        'Study Name' => 'Study 1',
        'Project Name' => 'Project 1',
        'Barcode' => group_1_tubes[index].human_barcode,
        'Asset Group Name' => 'Asset Group 1',
        'scRNA Core Number of Pools' => group_1_number_of_pools,
        'scRNA Core Cells per Chip Well' => group_1_cells_per_chip_well
      )
    end
  end
  let(:group_2_rows) do
    Array.new(group_2_number_of_samples) do |index|
      new_csv_row(
        'Study Name' => 'Study 2',
        'Project Name' => 'Project 2',
        'Barcode' => group_2_tubes[index].human_barcode,
        'Asset Group Name' => 'Asset Group 2',
        'scRNA Core Number of Pools' => group_2_number_of_pools,
        'scRNA Core Cells per Chip Well' => group_2_cells_per_chip_well
      )
    end
  end
  let(:group_3_rows) do
    Array.new(group_3_number_of_samples) do |index|
      new_csv_row(
        'Study Name' => 'Study 3',
        'Project Name' => 'Project 3',
        'Barcode' => group_3_tubes[index].human_barcode,
        'Asset Group Name' => 'Asset Group 3',
        'scRNA Core Number of Pools' => group_3_number_of_pools,
        'scRNA Core Cells per Chip Well' => group_3_cells_per_chip_well
      )
    end
  end
  # Combine the rows from all groups to create the CSV data.
  let(:csv_data) { group_1_rows + group_2_rows + group_3_rows }
  # The I18n scope for the error messages in the locale file.
  let(:i18n_scope) { described_class::I18N_SCOPE_SCRNA_CORE_CDNA_PREP_FEASIBILITY_VALIDATOR }
  # The total number of samples in the submission.
  let(:total_number_of_samples) { group_1_number_of_samples + group_2_number_of_samples + group_3_number_of_samples }
  # The total number of pools in the submission.
  let(:total_number_of_pools) { group_1_number_of_pools + group_2_number_of_pools + group_3_number_of_pools }

  # Defaults for the submission template and CSV data.
  let(:template_name) { 'Limber-Htp - scRNA Core cDNA Prep GEM-X 5p' }
  let(:scrna_core_number_of_pools) { 1 } # study-project
  let(:scrna_core_cells_per_chip_well) { 90_000 }

  # The request types are used to create the submission template record.
  let!(:request_types) { [create(:pbmc_pooling_customer_request_type)] }

  # User is created for the submission beforehand.
  let!(:user) { create(:user, login: 'user1') }

  # The submission template hash is used for creating the submission template
  # record using the SubmissionSerializer.construct! call.
  let(:submission_template_hash) do
    {
      name: template_name,
      submission_class_name: 'LinearSubmission',
      product_catalogue: 'scRNA Core',
      submission_parameters: {
        request_options: {},
        request_types: request_types.map(&:key)
      }
    }
  end

  # CSV headers and CSV data are combined to create the CSV content as string.
  let(:csv_content) do
    CSV.generate do |csv|
      csv << csv_headers
      csv_data.each { |row| csv << row }
    end
  end

  # A temporary file is created with the CSV content.
  let(:csv_tempfile) do
    # Use the Array form to enforce an extension in the filename.
    # Use new to control the lifecycle of the temporary file.
    Tempfile
      .new(%w[donor_pooling_validator_test .csv])
      .tap do |tempfile|
        tempfile.write(csv_content)
        tempfile.rewind # to make it ready for reading from the beginning.
      end
  end

  # The path of the temporary file is assigned to the spreadsheet path, which
  # is passed to the fixture_file_upload method to create an uploaded file
  # in order to initialise the test subject.
  let(:spreadsheet_path) { csv_tempfile.path }

  # The uploaded file is created using the fixture_file_upload method.
  let(:submission_file) { fixture_file_upload(spreadsheet_path) }

  # Helper method to create a new CSV row with the defaults and specified values.
  # The optional row_data hash argument is used to set the values corresponding
  # to the headers. Unspecified fields will be set to nil but they can be set
  # later directly on the row object. The nil fields are rendered as empty cells.
  # @example Create a new row with defaults, specified values, and more later.
  #   row = new_csv_row('User Login' => 'user1', 'Barcode' => 'FX12345678')
  #   row['Study Name'] = 'Study 1'
  #   row['Project Name'] = 'Project 1'
  #   row.to_s
  #   => "user1,Limber-Htp - scRNA Core cDNA Prep GEM-X 5p,Project 1,Study 1,,FX12345678,,,,,,,,,,,,,,,,,10,90000\n"
  # @param row_data [Hash] The values to be set in the new row: header => value.
  # @return [CSV::Row] The new CSV row.
  def new_csv_row(**row_data)
    CSV::Row
      .new(csv_headers, [nil] * csv_headers.size)
      .tap do |row|
        # Start with the defaults
        data = {
          'User Login' => user.login,
          'Template Name' => template_name,
          'scRNA Core Number of Pools' => scrna_core_number_of_pools,
          'scRNA Core Cells per Chip Well' => scrna_core_cells_per_chip_well
        }
        # Merge specified row_data values.
        data.merge!(row_data)

        # Set the values in the row.
        data.each { |key, value| row[key] = value }
      end
  end

  # Helper method to get the scrna_config hash from the Rails application config.
  # @return [Hash] The scrna_config hash.
  def scrna_config
    Rails.application.config.scrna_config
  end

  after do
    csv_tempfile.close! # Close and unlink the temporary file after the test.
  end

  describe '#validate_scrna_core_cdna_prep_total_number_of_samples' do
    # Total number of samples in the submission must be between 5 and 96 (inclusive).

    context 'when the total number of samples is between the minimum and maximum allowed' do
      let(:group_1_number_of_samples) { 15 }
      let(:group_2_number_of_samples) { 16 }
      let(:group_3_number_of_samples) { 17 }

      it { is_expected.to be_valid }
    end

    context 'when the total number of samples is the minimum allowed' do
      # This is possible with a single study-project group with 5 samples.
      let(:group_1_number_of_samples) { 5 }
      let(:group_2_number_of_samples) { 0 }
      let(:group_3_number_of_samples) { 0 }

      it { is_expected.to be_valid }
    end

    context 'when the total number of samples is the maximum allowed' do
      let(:group_1_number_of_samples) { 31 }
      let(:group_2_number_of_samples) { 32 }
      let(:group_3_number_of_samples) { 33 }

      let(:group_1_number_of_pools) { 2 }
      let(:group_2_number_of_pools) { 2 }
      let(:group_3_number_of_pools) { 2 }

      it { is_expected.to be_valid }
    end

    context 'when the total number of samples is less than the minimum allowed' do
      let(:group_1_number_of_samples) { 4 }
      let(:group_2_number_of_samples) { 0 }
      let(:group_3_number_of_samples) { 0 }

      # rubocop:disable RSpec/ExampleLength, RSpec/MultipleExpectations
      it 'adds the error message' do
        error_message =
          I18n.t(
            'errors.total_number_of_samples',
            min: scrna_config[:cdna_prep_minimum_total_number_of_samples],
            max: scrna_config[:cdna_prep_maximum_total_number_of_samples],
            count: total_number_of_samples,
            scope: i18n_scope
          )
        expect { bulk_submission.process }.to raise_error(ActiveRecord::RecordInvalid)
        expect(bulk_submission.errors[:spreadsheet]).to include(error_message)
      end
      # rubocop:enable RSpec/ExampleLength, RSpec/MultipleExpectations
    end

    context 'when the total number of samples is greater than the maximum allowed' do
      let(:group_1_number_of_samples) { 32 }
      let(:group_2_number_of_samples) { 32 }
      let(:group_3_number_of_samples) { 33 }

      let(:group_1_number_of_pools) { 3 }
      let(:group_2_number_of_pools) { 3 }
      let(:group_3_number_of_pools) { 2 }

      # rubocop:disable RSpec/ExampleLength, RSpec/MultipleExpectations
      it 'adds the error message' do
        error_message =
          I18n.t(
            'errors.total_number_of_samples',
            min: scrna_config[:cdna_prep_minimum_total_number_of_samples],
            max: scrna_config[:cdna_prep_maximum_total_number_of_samples],
            count: total_number_of_samples,
            scope: i18n_scope
          )
        expect { bulk_submission.process }.to raise_error(ActiveRecord::RecordInvalid)
        expect(bulk_submission.errors[:spreadsheet]).to include(error_message)
      end
      # rubocop:enable RSpec/ExampleLength, RSpec/MultipleExpectations
    end
  end

  describe '#validate_scrna_core_cdna_prep_total_number_of_pools' do
    # Total (requested) number of pools must be between 1 and 8 (inclusive)
    # Calculating total number of pools
    # Split the rows into study-project groups.
    # The 'number of pools' applies at that level - grab one number for this
    #   column for each of those groups and add them up.
    # e.g. Study A-Project A asks for 1 pool, Study A-Project B asks for 2
    #   pools, Study C-Project C asks for 5 pools --> total pools is
    #   1 + 2 + 5 = 8 --> passes

    context 'when the total number of pools is between the minimum and maximum allowed' do
      it { is_expected.to be_valid }
    end

    context 'when the total number of pools is the minimum allowed' do
      let(:group_1_number_of_samples) { 5 }
      let(:group_2_number_of_samples) { 0 }
      let(:group_3_number_of_samples) { 0 }

      let(:group_1_number_of_pools) { 1 }
      let(:group_2_number_of_pools) { 0 }
      let(:group_3_number_of_pools) { 0 }

      it { is_expected.to be_valid }
    end

    context 'when the total number of pools is the maximum allowed' do
      let(:group_1_number_of_samples) { 31 }
      let(:group_2_number_of_samples) { 32 }
      let(:group_3_number_of_samples) { 33 }

      let(:group_1_number_of_pools) { 3 }
      let(:group_2_number_of_pools) { 3 }
      let(:group_3_number_of_pools) { 2 }

      it { is_expected.to be_valid }
    end

    context 'when the total number of pools is less than the minimum allowed' do
      let(:group_1_number_of_samples) { 5 }
      let(:group_2_number_of_samples) { 0 }
      let(:group_3_number_of_samples) { 0 }

      let(:group_1_number_of_pools) { 1 }
      let(:group_2_number_of_pools) { 0 }
      let(:group_3_number_of_pools) { 0 }

      before do
        # Because the allowed range for the total number of pools is configured
        # as 1 to 8 (inclusive), testing it below the minimum value requires
        # setting a zero number of pools, which causes a ZeroDivisionError
        # before the feasibility validation. In order to test the error message,
        # we will use a different range; 2 to 8 instead of 1 to 8. We will stub
        # the scrna_config call on the Rails.application.config to return the
        # modified scrna_config.
        scrna_config_dup = Rails.application.config.scrna_config.dup
        scrna_config_dup[:cdna_prep_minimum_total_number_of_pools] = 2
        allow(Rails.application.config).to receive(:scrna_config).and_return(scrna_config_dup)
      end

      # rubocop:disable RSpec/ExampleLength, RSpec/MultipleExpectations
      it 'adds the error message' do
        error_message =
          I18n.t(
            'errors.total_number_of_pools',
            min: scrna_config[:cdna_prep_minimum_total_number_of_pools],
            max: scrna_config[:cdna_prep_maximum_total_number_of_pools],
            count: total_number_of_pools,
            scope: i18n_scope
          )
        expect { bulk_submission.process }.to raise_error(ActiveRecord::RecordInvalid)
        expect(bulk_submission.errors[:spreadsheet]).to include(error_message)
      end
      # rubocop:enable RSpec/ExampleLength, RSpec/MultipleExpectations
    end

    context 'when the total number of pools is greater than the maximum allowed' do
      let(:group_1_number_of_samples) { 31 }
      let(:group_2_number_of_samples) { 32 }
      let(:group_3_number_of_samples) { 33 }

      let(:group_1_number_of_pools) { 3 }
      let(:group_2_number_of_pools) { 3 }
      let(:group_3_number_of_pools) { 3 }

      # rubocop:disable RSpec/ExampleLength, RSpec/MultipleExpectations
      it 'adds the error message' do
        error_message =
          I18n.t(
            'errors.total_number_of_pools',
            min: scrna_config[:cdna_prep_minimum_total_number_of_pools],
            max: scrna_config[:cdna_prep_maximum_total_number_of_pools],
            count: total_number_of_pools,
            scope: i18n_scope
          )
        expect { bulk_submission.process }.to raise_error(ActiveRecord::RecordInvalid)
        expect(bulk_submission.errors[:spreadsheet]).to include(error_message)
      end
      # rubocop:enable RSpec/ExampleLength, RSpec/MultipleExpectations
    end
  end

  describe '#validate_scrna_core_cdna_prep_feasibility_by_samples' do
    # The number of pools requested must be feasible given the number of samples.
    # Checking if the number of pools is feasible, given number of samples
    # For each study-project group:
    # Smallest pool = Number of samples / number of pools (floor division)
    # Biggest pool = Smallest pool + 1 (if remainder is positive)
    # Check both smallest pool and biggest pool are between 5 and 25 (inclusive).
    # Note that only the smallest pool is validated in the following cases:
    # - if the remainder is zero; the smallest and biggest pool sizes are equal.
    # - if the number of pools is one; there is only one pool.
    context 'when the pool sizes are between the minimum and maximum allowed' do
      let(:group_1_number_of_samples) { 10 }
      let(:group_2_number_of_samples) { 30 }
      let(:group_3_number_of_samples) { 56 }

      let(:group_1_number_of_pools) { 1 } # 10: (5 < 10 < 25)
      let(:group_2_number_of_pools) { 2 } # 15, 15:(5 < 15 < 25)
      let(:group_3_number_of_pools) { 3 } # 18, 19, 19: (5 < 18 < 25) and (5 < 19 < 25)

      it { is_expected.to be_valid }
    end

    context 'when the smallest pool size is the minimum allowed' do
      let(:group_1_number_of_samples) { 5 }
      let(:group_2_number_of_samples) { 11 }
      let(:group_3_number_of_samples) { 29 }

      let(:group_1_number_of_pools) { 1 }
      let(:group_2_number_of_pools) { 2 }
      let(:group_3_number_of_pools) { 5 }

      it { is_expected.to be_valid }
    end

    context 'when the biggest pool size is the maximum allowed' do
      let(:group_1_number_of_samples) { 25 }
      let(:group_2_number_of_samples) { 49 }
      let(:group_3_number_of_samples) { 0 } # not included in the test

      let(:group_1_number_of_pools) { 1 }
      let(:group_2_number_of_pools) { 2 }
      let(:group_3_number_of_pools) { 1 }

      it { is_expected.to be_valid }
    end

    context 'when the smallest pool size is less than the minimum allowed' do
      let(:group_1_number_of_samples) { 4 } # smallest = biggest < 5
      let(:group_2_number_of_samples) { 9 } # smallest < 5, biggest: OK
      let(:group_3_number_of_samples) { 7 } # smallest < 5, biggest < 5

      let(:group_1_number_of_pools) { 1 }
      let(:group_2_number_of_pools) { 2 }
      let(:group_3_number_of_pools) { 2 }

      # rubocop:disable RSpec/ExampleLength, RSpec/MultipleExpectations
      it 'adds the error message' do
        expect { bulk_submission.process }.to raise_error(ActiveRecord::RecordInvalid)

        # Parametrise the assertions for the error messages because multiple
        # error messages are expected for different study-project groups and
        # pool sizes (smallest and biggest).

        # study name, project name, pool size, size type
        params = [
          ['Study 1', 'Project 1', 4, 'smallest'],
          ['Study 2', 'Project 2', 4, 'smallest'],
          ['Study 3', 'Project 3', 3, 'smallest'],
          ['Study 3', 'Project 3', 4, 'biggest']
        ]
        params.each do |study_name, project_name, pool_size, size_type|
          error_message =
            I18n.t(
              'errors.number_of_pools_by_samples',
              study_name: study_name,
              project_name: project_name,
              min: scrna_config[:cdna_prep_minimum_number_of_samples_per_pool],
              max: scrna_config[:cdna_prep_maximum_number_of_samples_per_pool],
              count: pool_size,
              size_type: size_type, # smallest or biggest
              scope: i18n_scope
            )
          expect(bulk_submission.errors[:spreadsheet]).to include(error_message)
        end
      end
      # rubocop:enable RSpec/ExampleLength, RSpec/MultipleExpectations
    end

    context 'when the biggest pool size is greater than the maximum allowed' do
      let(:group_1_number_of_samples) { 51 } # smallest:OK, biggest > 25
      let(:group_2_number_of_samples) { 0 }
      let(:group_3_number_of_samples) { 0 }

      let(:group_1_number_of_pools) { 2 }
      let(:group_2_number_of_pools) { 1 }
      let(:group_3_number_of_pools) { 1 }

      # rubocop:disable RSpec/ExampleLength, RSpec/MultipleExpectations
      it 'adds the error message' do
        error_message =
          I18n.t(
            'errors.number_of_pools_by_samples',
            study_name: 'Study 1',
            project_name: 'Project 1',
            min: scrna_config[:cdna_prep_minimum_number_of_samples_per_pool],
            max: scrna_config[:cdna_prep_maximum_number_of_samples_per_pool],
            count: 26,
            size_type: 'biggest',
            scope: i18n_scope
          )
        expect { bulk_submission.process }.to raise_error(ActiveRecord::RecordInvalid)
        expect(bulk_submission.errors[:spreadsheet]).to include(error_message)
      end
      # rubocop:enable RSpec/ExampleLength, RSpec/MultipleExpectations
    end
  end

  describe '#validate_scrna_core_cdna_prep_feasibility_by_donors' do
    # The number of pools requested must be feasible having checked for donor clash.
    # Checking for donor clash
    # For each study-project group:
    # Group the samples by their donor id.
    # Find the biggest group (will be 1 if all samples have unique donor ids)
    # Check size of biggest group <= requested number of pools.
    context 'when the number of samples with the same donor ID is less than ' \
            'or equal to the requested number of pools for study and project' do
      let(:group_1_number_of_samples) { 96 }
      let(:group_2_number_of_samples) { 0 } # not included in the test
      let(:group_3_number_of_samples) { 0 } # not included in the test

      let(:group_1_number_of_pools) { 4 }
      let(:group_2_number_of_pools) { 1 }
      let(:group_3_number_of_pools) { 1 }

      let(:group_1_donors) do
        donors = Array.new(group_1_number_of_samples) { |index| "group_1_donor_#{index + 1}" }
        donors[0..2] = [donors[0]] * 3 # samples with the same donor ID
        donors
      end

      # We can put the first 3 samples into separate pools to avoid donor clash,
      # because we have 4 pools.
      it { is_expected.to be_valid }
    end

    context 'when the number of samples with the same donor ID is equal to ' \
            'the requested number of pools for study and project' do
      let(:group_1_number_of_samples) { 96 }
      let(:group_2_number_of_samples) { 0 } # not included in the test
      let(:group_3_number_of_samples) { 0 } # not included in the test

      let(:group_1_number_of_pools) { 4 }
      let(:group_2_number_of_pools) { 1 }
      let(:group_3_number_of_pools) { 1 }

      let(:group_1_donors) do
        donors = Array.new(group_1_number_of_samples) { |index| "group_1_donor_#{index + 1}" }
        donors[0..3] = [donors[0]] * 4 # samples with the same donor ID
        donors
      end

      # We can put the first 4 samples into separate pools to avoid donor clash,
      # because we have 4 pools.
      it { is_expected.to be_valid }
    end

    context 'when the number of samples with the same donor ID is greater ' \
            'than the requested number of pools for study and project' do
      let(:group_1_number_of_samples) { 96 }
      let(:group_2_number_of_samples) { 0 } # not included in the test
      let(:group_3_number_of_samples) { 0 } # not included in the test

      let(:group_1_number_of_pools) { 4 }
      let(:group_2_number_of_pools) { 1 }
      let(:group_3_number_of_pools) { 1 }

      let(:group_1_donors) do
        donors = Array.new(group_1_number_of_samples) { |index| "group_1_donor_#{index + 1}" }
        donors[0..4] = [donors[0]] * 5 # samples with the same donor ID
        donors
      end

      # We cannot put the first 5 samples into separate pools to avoid donor
      # clash, because we have 4 pools.

      # rubocop:disable RSpec/ExampleLength, RSpec/MultipleExpectations
      it 'adds the error message' do
        # Barcodes or well locations of the labware with the same donor ID are
        # listed in the error message. This test uses tubes; hence the barcodes
        # of the tubes will be listed to help the user identify the samples.
        barcodes_or_well_locations = group_1_tubes[0..4].map(&:human_barcode).join(', ')

        error_message =
          I18n.t(
            'errors.number_of_pools_by_donors',
            study_name: 'Study 1',
            project_name: 'Project 1',
            count: 5, # biggest donor group size
            number_of_pools: group_1_number_of_pools, # requested number of pools
            barcodes_or_well_locations: barcodes_or_well_locations,
            scope: i18n_scope
          )
        expect { bulk_submission.process }.to raise_error(ActiveRecord::RecordInvalid)
        expect(bulk_submission.errors[:spreadsheet]).to include(error_message)
      end
      # rubocop:enable RSpec/ExampleLength, RSpec/MultipleExpectations
    end
  end

  describe '#validate_scrna_core_cdna_prep_full_allowance' do
    # There is not enough material for the "full allowance" (2 full runs on the
    # chip) for the smallest pool size for a study-project group.
    context 'when final_resuspension_volume is greater than the full allowance' do
      let(:group_1_number_of_samples) { 5 }
      let(:group_2_number_of_samples) { 0 } # not included in the test
      let(:group_3_number_of_samples) { 0 } # not included in the test

      let(:group_1_number_of_pools) { 1 }
      let(:group_2_number_of_pools) { 1 }
      let(:group_3_number_of_pools) { 1 }

      # rubocop:disable RSpec/MultipleExpectations, RSpec/ExampleLength
      it 'adds the warning message' do
        warning_message =
          I18n.t(
            'warnings.full_allowance',
            study_name: 'Study 1',
            project_name: 'Project 1',
            number_of_samples_in_smallest_pool: 5,
            final_resuspension_volume: '59.4',
            full_allowance: '100.0',
            scope: i18n_scope
          )

        expect(bulk_submission).to be_valid
        expect(bulk_submission.warnings[:spreadsheet]).to include(warning_message)
      end
      # rubocop:enable RSpec/MultipleExpectations, RSpec/ExampleLength
    end

    context 'when final_resuspension_volume is equal to the full allowance' do
      let(:group_1_number_of_samples) { 5 }
      let(:group_2_number_of_samples) { 0 } # not included in the test
      let(:group_3_number_of_samples) { 0 } # not included in the test

      let(:group_1_number_of_pools) { 1 }
      let(:group_2_number_of_pools) { 1 }
      let(:group_3_number_of_pools) { 1 }

      let(:group_1_cells_per_chip_well) { 41_250 }

      # rubocop:disable RSpec/MultipleExpectations
      it 'adds the warning message' do
        expect(bulk_submission).to be_valid
        expect(bulk_submission.warnings).to be_empty
      end
      # rubocop:enable RSpec/MultipleExpectations
    end

    context 'when final resuspension volume is less than the full allowance' do
      let(:group_1_number_of_samples) { 5 }
      let(:group_2_number_of_samples) { 0 } # not included in the test
      let(:group_3_number_of_samples) { 0 } # not included in the test

      let(:group_1_number_of_pools) { 1 }
      let(:group_2_number_of_pools) { 1 }
      let(:group_3_number_of_pools) { 1 }

      let(:group_1_cells_per_chip_well) { 30_000 }

      # rubocop:disable RSpec/MultipleExpectations
      it 'does not add the warning message' do
        expect(bulk_submission).to be_valid
        expect(bulk_submission.warnings).to be_empty
      end
      # rubocop:enable RSpec/MultipleExpectations
    end

    context 'when there are multiple full allowance warnings' do
      let(:group_1_number_of_samples) { 5 }
      let(:group_2_number_of_samples) { 5 }
      let(:group_3_number_of_samples) { 5 }

      let(:group_1_number_of_pools) { 1 }
      let(:group_2_number_of_pools) { 1 }
      let(:group_3_number_of_pools) { 1 }

      # rubocop:disable RSpec/MultipleExpectations, RSpec/ExampleLength
      it 'adds the warning message for each study-project' do
        expect(bulk_submission).to be_valid

        params = [['Study 1', 'Project 1'], ['Study 2', 'Project 2'], ['Study 3', 'Project 3']]
        params.each do |study_name, project_name|
          warning_message =
            I18n.t(
              'warnings.full_allowance',
              study_name: study_name,
              project_name: project_name,
              number_of_samples_in_smallest_pool: 5,
              final_resuspension_volume: '59.4',
              full_allowance: '100.0',
              scope: i18n_scope
            )
          expect(bulk_submission.warnings[:spreadsheet]).to include(warning_message)
        end
      end
      # rubocop:enable RSpec/MultipleExpectations, RSpec/ExampleLength
    end
  end

  describe '#validate_scrna_core_cdna_prep_total_number_of_pools_is_not_zero?' do
    context 'when the number of pools is zero in any study-project group' do
      let(:group_1_number_of_pools) { 0 }
      let(:group_2_number_of_pools) { 0 }
      let(:group_3_number_of_pools) { 0 }

      it 'raises a RecordInvalid error' do
        expect { bulk_submission.process }.to raise_error(ActiveRecord::RecordInvalid)
      end

      it 'adds the error message' do
        expect do
          bulk_submission.process
        rescue ActiveRecord::RecordInvalid
          # expected to raise RecordInvalid
        end.to change { bulk_submission.errors[:spreadsheet] }
          .to include(I18n.t('errors.number_of_pools_exists', scope: i18n_scope))
      end
    end
  end
end
