# frozen_string_literal: true

require 'rails_helper'

describe 'Bulk submission', js: false do
  let(:user) { create(:admin, login: 'user') }
  let(:study) { create(:study, name: 'abc123_study') }

  def process_submission(filename, encoding = nil)
    attach_file('bulk_submission_spreadsheet', Rails.root.join('features', 'submission', 'csv', filename))
    select(encoding, from: 'Encoding') if encoding
    click_button 'Create Bulk submission'
  end

  before do
    login_user user
    create(:project, name: 'Test project')
    create(:asset_group, name: 'assetgroup123', study:, asset_count: 2)
    visit bulk_submissions_path
    expect(page).to have_content('Bulk Submission New')
    create(:library_type, name: 'Standard')
  end

  shared_examples 'bulk submission file upload' do
    it 'allows file upload' do
      process_submission(file_name, encoding)
      expect(page).to have_content expected_content
      expect(Submission.count).to eq(submission_count) if submission_count
    end
  end

  let(:library_request_type) { create(:library_request_type) }
  let(:sequencing_request_type) { create(:sequencing_request_type, read_lengths: [100], default: 100) }

  let(:submission_template_hash) do
    {
      name: template_name,
      submission_class_name: 'LinearSubmission',
      product_catalogue: 'Generic',
      superceded_by_id: deprecated ? -2 : -1,
      submission_parameters: {
        info_differential: 5,
        request_options: {
          'fragment_size_required_to' => '400',
          'fragment_size_required_from' => '100'
        },
        request_types: [library_request_type.key, sequencing_request_type.key]
      }
    }
  end

  let(:deprecated) { false }

  context 'with default encoding' do
    let(:template_name) { 'Illumina-A - Cherrypick for pulldown - Pulldown WGS - HiSeq Paired end sequencing' }
    before { SubmissionSerializer.construct!(submission_template_hash) }

    let(:encoding) { nil }

    context 'with one submission' do
      let(:submission_count) { 1 }

      context 'Uploading a valid file with 1 submission' do
        let(:file_name) { '1_valid_rows.csv' }
        let(:expected_content) { 'Your bulk submission has been processed.' }

        it_behaves_like 'bulk submission file upload'

        it 'sets bait library' do
        end
      end

      context 'With an empty column' do
        # Files can have empty columns appended onto the end.
        # We should just ignore these.
        let(:template_name) { 'Example template' }
        let(:file_name) { 'with_empty_column.csv' }
        let(:expected_content) { 'Your bulk submission has been processed' }

        it_behaves_like 'bulk submission file upload'
      end

      context 'With a moved header' do
        # Occasionally users move the header row around, and insert or delete rows.
        # We should still be able to process the file
        let(:template_name) { 'Example template' }
        let(:file_name) { 'with_moved_header.csv' }
        let(:expected_content) { 'Your bulk submission has been processed' }

        it_behaves_like 'bulk submission file upload'
      end
    end

    context 'Uploading a valid file with gb expected specified should set the gb expected' do
      let(:file_name) { '2_valid_rows.csv' }
      let(:submission_count) { 2 }
      let(:expected_content) { 'Your bulk submission has been processed.' }

      it 'allows file upload' do
        process_submission(file_name)
        expect(page).to have_content expected_content
        expect(Order.last.request_options['gigabases_expected']).to eq('1.35')
      end
    end

    context 'with no submissions' do
      let(:submission_count) { 0 }

      context 'Uploading a valid file with 1 submission but a deprecated template' do
        let(:template_name) { 'Cherrypick for pulldown - Pulldown WGS - HiSeq Paired end sequencing' }
        let(:deprecated) { true }
        let(:file_name) { '1_deprecated_rows.csv' }
        let(:expected_content) do
          # rubocop:todo Layout/LineLength
          "Template: 'Cherrypick for pulldown - Pulldown WGS - HiSeq Paired end sequencing' is deprecated and no longer in use."
          # rubocop:enable Layout/LineLength
        end

        it_behaves_like 'bulk submission file upload'
      end

      context 'Uploading an invalid file with 1 submissions' do
        let(:file_name) { '1_invalid_rows.csv' }
        let(:expected_content) { 'No user specified for testing124' }

        it_behaves_like 'bulk submission file upload'
      end

      context 'Uploading an invalid file with 2 submissions' do
        let(:file_name) { '2_invalid_rows.csv' }
        let(:expected_content) { 'There was a problem on row(s)' }

        it_behaves_like 'bulk submission file upload'
      end

      context 'Uploading a file with conflicting orders' do
        let(:file_name) { 'with_conflicting_submissions.csv' }
        let(:expected_content) { "read length should be identical for all requests in asset group 'assetgroup123'" }

        it_behaves_like 'bulk submission file upload'
      end

      context 'Uploading an invalid file with 2 submissions' do
        let(:file_name) { '1_valid_1_invalid.csv' }
        let(:expected_content) { 'There was a problem on row(s)' }

        it_behaves_like 'bulk submission file upload'
      end

      context 'Uploading an empty file' do
        let(:file_name) { 'no_rows.csv' }
        let(:expected_content) { 'The supplied file was empty' }

        it_behaves_like 'bulk submission file upload'
      end

      context 'Uploading a file without a (valid) header row' do
        let(:file_name) { 'bad_header.csv' }
        let(:expected_content) { 'The supplied file does not contain a valid header row' }

        it_behaves_like 'bulk submission file upload'
      end

      context 'Uploading an invalid file with 1 submissions Windows-1252 encoded characters' do
        let(:file_name) { 'invalid_cp1252_rows.csv' }
        let(:expected_content) { 'abc123 — study' }

        it_behaves_like 'bulk submission file upload'
      end

      context 'Leaving the file field blank' do
        it 'produces an error' do
          click_button 'Create Bulk submission'
          expect(page).to have_content("can't be blank")
        end
      end

      context 'With no header iver one column' do
        # If a header is missing, let the user know, rather than doing something unexpected
        let(:template_name) { 'Example template' }
        let(:file_name) { 'with_headerless_column.csv' }
        let(:expected_content) { 'Row 2, column 4 contains data but no heading.' }

        it_behaves_like 'bulk submission file upload'
      end
    end
  end

  context 'Uploading an invalid file with 1 submissions utf-8 encoded characters' do
    let(:file_name) { 'invalid_utf8_rows.csv' }
    let(:encoding) { 'UTF-8' }
    let(:expected_content) { 'abc123 — study' }
    let(:submission_count) { 0 }

    it_behaves_like 'bulk submission file upload'
  end
end
