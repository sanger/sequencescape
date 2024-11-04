# frozen_string_literal: true

require 'rails_helper'

describe BulkSubmission, with: :uploader do
  subject(:bulk_submission) { described_class.new(spreadsheet: submission_file, encoding: encoding) }

  let(:encoding) { 'Windows-1252' }
  let(:spreadsheet_path) { Rails.root.join('spec', 'data', 'submission', spreadsheet_filename) }

  # NB. fixture_file_upload is a Rails method on ActionDispatch::TestProcess::FixtureFile
  let(:submission_file) { fixture_file_upload(spreadsheet_path) }

  let(:number_submissions_created) { subject.completed_submissions.first.length }
  let(:generated_submissions) { Submission.find(subject.completed_submissions.first) }
  let(:generated_submission) { generated_submissions.first }
  let(:request_types) { create_list(:well_request_type, 2) }

  let!(:study) { create(:study, name: 'Test Study') }
  let!(:plate) { create(:plate_with_tagged_wells, sample_count: 96, barcode: 'SQPD-12345') }
  let!(:asset_group) do
    create(:asset_group, name: 'assetgroup', study: study, assets: plate.wells)
  end
  let!(:library_type) { create(:library_type, name: 'Standard') }

  after { submission_file.close }

  before do
    create(:user, login: 'user')
    create(:project, name: 'Test project')
  end

  context 'when an scRNA Bulk Submission for plate' do
    let(:spreadsheet_filename) { 'scRNA_bulk_submission.csv' }
    let(:submission_template_hash) do
      {
        name: 'Limber-Htp - scRNA Core cDNA Prep GEM-X 5p',
        submission_class_name: 'LinearSubmission',
        product_catalogue: 'Generic',
        submission_parameters: {
          request_options: {},
          request_types: request_types.map(&:key)
        }
      }
    end

    before { SubmissionSerializer.construct!(submission_template_hash) }

    it 'is valid' do
      expect(bulk_submission).to be_valid
    end

    it 'generates submissions when processed' do
      bulk_submission.process
      expect(number_submissions_created).to eq(1)
    end
  end

end
