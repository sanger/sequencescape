require 'rails_helper'

describe BulkSubmission, with: :uploader do
  let(:encoding) { 'Windows-1252' }
  let(:spreadsheet_path) { Rails.root.join('features', 'submission', 'csv', spreadsheet_filename) }
  let(:submission_file) { fixture_file_upload(spreadsheet_path) }

  after(:each) { submission_file.close }

  before(:each) do
    create :user, login: 'user'
    study = create :study, name: 'abc123_study'
    create :project, name: 'Test project'
    create :asset_group, name: 'assetgroup123', study: study, asset_count: 2
  end

  subject do
    BulkSubmission.new(spreadsheet: submission_file, encoding: encoding)
  end

  context 'a simple submission' do
    let(:spreadsheet_filename) { '1_valid_rows.csv' }
    let(:number_submissions_created) { subject.completed_submissions.first.length }
    let(:generated_submissions) { Submission.find(subject.completed_submissions.first) }
    let(:generated_submission) { generated_submissions.first }

    it 'is valid' do
      expect(subject).to be_valid
    end
    it 'generates submissions when processed' do
      subject.process
      expect(number_submissions_created).to eq(1)
    end
    it 'generates submissions with one order' do
      subject.process
      expect(generated_submission.orders.count).to eq(1)
    end
  end

  context 'a submission with PCR cycles' do
    let(:spreadsheet_filename) { 'pcr_cycles.csv' }
    let(:number_submissions_created) { subject.completed_submissions.first.length }
    let(:generated_submissions) { Submission.find(subject.completed_submissions.first) }
    let(:generated_submission) { generated_submissions.first }
    let(:submission_template) { create :limber_wgs_submission_template, name: 'limber wgs' }
    let(:request_type) { submission_template.submission_parameters[:request_type_ids_list].first.first.to_s }

    before(:each) do
      submission_template
    end

    let(:expected_request_options) do
      {
        'fragment_size_required_to' => '400',
        'fragment_size_required_from' => '100',
        'pcr_cycles' => '5',
        'read_length' => '100',
        'library_type' => 'Standard',
        'multiplier' => { request_type => 1 }
      }
    end

    it 'is valid' do
      expect(subject).to be_valid
    end
    it 'sets the expected request options' do
      subject.process
      expect(generated_submission.orders.first.request_options).to eq(expected_request_options)
    end
  end
end
