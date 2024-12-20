# frozen_string_literal: true

require 'rails_helper'

# This spec tests the Submission::DonorPoolingValidator module included by the
# BulkSubmission class through the Submission::ValidationsByTemplateName module.
# CSV files are created for bulk submissions and the validations provided by
# the validator module are tested.
RSpec.describe BulkSubmission, with: :uploader do
  # The CSV file headers have been copied form the headings in the config file
  # config/bulk_submission_excel/worksheet/data_worksheet.rb
  # The test subject is initialised with the uploaded file.
  subject(:bulk_submission) { described_class.new(spreadsheet: submission_file) }

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
      'scRNA Core Number of Samples per Pool',
      'scRNA Core Cells per Chip Well'
    ]
  end
  # Defaults for the submission template and CSV data.
  let(:template_name) { 'Limber-Htp - scRNA Core cDNA Prep GEM-X 5p' }
  let(:scrna_core_number_of_samples_per_pool) { 10 }
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

  # Each test context will specify different rows of data.
  let(:csv_data) { [] }

  # CSV headers and data are combined to create the CSV content as string.
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
  # later directly on the row object.
  # @example Create a new row with defaults, specified values, and more later
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
          'scRNA Core Number of Samples per Pool' => scrna_core_number_of_samples_per_pool,
          'scRNA Core Cells per Chip Well' => scrna_core_cells_per_chip_well
        }
        # Merge specified row_data values.
        data.merge!(row_data)

        # Set the values in the row.
        data.each { |key, value| row[key] = value }
      end
  end

  before do
    SubmissionSerializer.construct!(submission_template_hash) # Create the template.
  end

  after do
    csv_tempfile.close! # Close and unlink the temporary file after the test.
  end

  context 'with total number of samples in the submission' do
    let(:total_number_of_samples) { described_class::SCRNA_CORE_MAX_TOTAL_NUMBER_OF_SAMPLES / 2 }
    let(:number_of_study_project_groups) { 2 }
    let(:tubes) { create_list(:sample_tube, total_number_of_samples) }
    let(:csv_data) do
      group_size = total_number_of_samples / number_of_study_project_groups
      (1..total_number_of_samples).map do |index|
        new_csv_row(
          'Study Name' => "Study #{(index / group_size) + 1}",
          'Project Name' => "Project #{(index / group_size) + 1}",
          'Barcode' => tubes[index - 1].human_barcode,
          # Study and Project must be identical in the same Asset Group.
          'Asset Group Name' => "Asset Group #{(index / group_size) + 1}"
        )
      end
    end
    let(:error_message) do
      format(
        described_class::SCRNA_CORE_ERROR_TOTAL_NUMBER_OF_SAMPLES,
        described_class::SCRNA_CORE_MIN_TOTAL_NUMBER_OF_SAMPLES,
        described_class::SCRNA_CORE_MAX_TOTAL_NUMBER_OF_SAMPLES
      )
    end

    context 'when the total number of samples is between minimum and maximum allowed' do
      it { is_expected.to be_valid }
    end

    context 'when the total number of samples is minimum allowed' do
      let(:total_number_of_samples) { described_class::SCRNA_CORE_MIN_TOTAL_NUMBER_OF_SAMPLES }

      it { is_expected.to be_valid }
    end

    context 'when the total number of samples is maximum allowed' do
      let(:total_number_of_samples) { described_class::SCRNA_CORE_MAX_TOTAL_NUMBER_OF_SAMPLES }

      it { is_expected.to be_valid }
    end

    context 'when the total number of samples is less than the minimum allowed' do
      let(:total_number_of_samples) { described_class::SCRNA_CORE_MIN_TOTAL_NUMBER_OF_SAMPLES - 1 }

      it { is_expected.not_to be_valid }

      it 'sets the error message' do
        bulk_submission.process # to run the validations
        expect(bulk_submission.errors[:spreadsheet]).to include(error_message)
      end
    end

    context 'when the total number of samples is more than the maximum allowed' do
      let(:total_number_of_samples) { described_class::SCRNA_CORE_MAX_TOTAL_NUMBER_OF_SAMPLES + 1 }

      it { is_expected.not_to be_valid }

      it 'sets the error message' do
        bulk_submission.process # to run the validations
        expect(bulk_submission.errors[:spreadsheet]).to include(error_message)
      end
    end
  end
end
