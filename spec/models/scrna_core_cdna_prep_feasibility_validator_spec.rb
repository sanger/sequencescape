# frozen_string_literal: true

require 'rails_helper'

# This spec tests the Submission::ScrnaCoreCdnaPrepFeasibilityValidator module
# included by the BulkSubmission class through the ValidationsByTemplateName
# module. CSV files are created for bulk submissions and the validations
# provided by the module are tested.
RSpec.describe BulkSubmission, with: :uploader do
  # The test subject is initialised with the uploaded file.
  subject(:bulk_submission) { described_class.new(spreadsheet: submission_file) }

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

  # Defaults for the submission template and CSV data.
  let(:template_name) { 'Limber-Htp - scRNA Core cDNA Prep GEM-X 5p' }
  let(:scrna_core_number_of_pools) { 2 } # study-project
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
        request_options: {
        },
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

  before do
    SubmissionSerializer.construct!(submission_template_hash) # Create the template.
  end

  after do
    csv_tempfile.close! # Close and unlink the temporary file after the test.
  end

  # Three study-project groups with different number of samples.
  let(:group_1_number_of_samples) { 15 } # Study 1, Project 1
  let(:group_2_number_of_samples) { 15 }
  let(:group_3_number_of_samples) { 15 }

  # The number of pools for each study-project group.
  let(:group_1_number_of_pools) { 1 }
  let(:group_2_number_of_pools) { 1 }
  let(:group_3_number_of_pools) { 1 }

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
        'scRNA Core Number of Pools' => group_1_number_of_pools
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
        'scRNA Core Number of Pools' => group_2_number_of_pools
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
        'scRNA Core Number of Pools' => group_3_number_of_pools
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

  context '#validate_scrna_core_cdna_prep_total_number_of_samples' do
    # Total number of samples in the submission must be between 5 and 96 (inclusive).

    context 'when the total number of samples is between minimum and maximum allowed' do
      it { is_expected.to be_valid }
    end

    context 'when the total number of samples is the minimum allowed' do
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
      it 'sets the error message' do
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
      it 'sets the error message' do
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

  context '#validate_scrna_core_cdna_prep_total_number_of_pools' do
    # Total (requested) number of pools must be between 1 and 8 (inclusive)

    context 'when the total number of pools is between minimum and maximum allowed' do
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

      it 'sets the error message' do
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
    end

    context 'when the total number of pools is greater than the maximum allowed' do
      let(:group_1_number_of_samples) { 31 }
      let(:group_2_number_of_samples) { 32 }
      let(:group_3_number_of_samples) { 33 }

      let(:group_1_number_of_pools) { 3 }
      let(:group_2_number_of_pools) { 3 }
      let(:group_3_number_of_pools) { 3 }

      it 'sets the error message' do
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
    end
  end
end
