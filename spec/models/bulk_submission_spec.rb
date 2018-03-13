require 'rails_helper'

describe BulkSubmission, with: :uploader do
  let(:encoding) { 'Windows-1252' }
  let(:spreadsheet_path) { Rails.root.join('features', 'submission', 'csv', spreadsheet_filename) }
  let(:submission_file) { fixture_file_upload(spreadsheet_path) }

  let(:number_submissions_created) { subject.completed_submissions.first.length }
  let(:generated_submissions) { Submission.find(subject.completed_submissions.first) }
  let(:generated_submission) { generated_submissions.first }

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
    setup do
      submission_template_hash = {
        name: 'Illumina-A - Cherrypick for pulldown - Pulldown WGS - HiSeq Paired end sequencing',
        submission_class_name: 'LinearSubmission',
        product_catalogue: 'Generic',
        superceeded_by_id: -2,
        submission_parameters: { info_differential: 5,
                                 request_options: { 'fragment_size_required_to' => '400',
                                                    'fragment_size_required_from' => '100' },
                                 request_types: ['cherrypick_for_pulldown',
                                                 'pulldown_wgs',
                                                 'illumina_a_hiseq_paired_end_sequencing'] }
      }
      SubmissionSerializer.construct!(submission_template_hash)
    end

    let(:spreadsheet_filename) { '1_valid_rows.csv' }

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

    let!(:submission_template) do
      create :limber_wgs_submission_template,
             name: 'pcr_cycle_test',
             request_types: [request_type]
    end
    let(:request_type) { create(:library_request_type) }

    let(:expected_request_options) do
      {
        'fragment_size_required_to' => '400',
        'fragment_size_required_from' => '100',
        'pcr_cycles' => '5',
        'read_length' => '100',
        'library_type' => 'Standard',
        'multiplier' => { request_type.id.to_s => 1 }
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

  context 'a submission with primer_panels' do
    let(:spreadsheet_filename) { 'primer_panels.csv' }
    let!(:primer_panel) { create :primer_panel, name: 'Test panel' }

    let!(:submission_template) do
      create :limber_wgs_submission_template,
             name: 'primer_panel_test',
             request_types: [request_type]
    end
    let(:request_type) { create(:gbs_request_type) }

    let(:expected_request_options) do
      {
        'fragment_size_required_to' => '400',
        'fragment_size_required_from' => '100',
        'pcr_cycles' => '5',
        'read_length' => '100',
        'library_type' => 'Standard',
        'primer_panel_name' => 'Test panel',
        'multiplier' => { request_type.id.to_s => 1 }
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
