require 'rails_helper'

describe BulkSubmission, with: :uploader do
  let(:encoding) { 'Windows-1252' }
  let(:spreadsheet_path) { Rails.root.join('features', 'submission', 'csv', spreadsheet_filename) }
  let(:submission_file) { fixture_file_upload(spreadsheet_path) }

  let(:number_submissions_created) { subject.completed_submissions.first.length }
  let(:generated_submissions) { Submission.find(subject.completed_submissions.first) }
  let(:generated_submission) { generated_submissions.first }
  let(:request_types) { create_list :well_request_type, 2 }

  after(:each) { submission_file.close }

  let!(:study) { create :study, name: 'abc123_study' }
  let!(:asset_group) { create :asset_group, name: 'assetgroup123', study: study, asset_count: 2 }

  before do
    create :user, login: 'user'
    create :project, name: 'Test project'
  end

  subject do
    BulkSubmission.new(spreadsheet: submission_file, encoding: encoding)
  end

  context 'a simple submission' do
    let(:submission_template_hash) do
      {
        name: 'Illumina-A - Cherrypick for pulldown - Pulldown WGS - HiSeq Paired end sequencing',
        submission_class_name: 'LinearSubmission',
        product_catalogue: 'Generic',
        superceeded_by_id: -2,
        submission_parameters: { info_differential: 5,
                                 request_options: { 'fragment_size_required_to' => '400',
                                                    'fragment_size_required_from' => '100' },
                                 request_types: request_types.map(&:key) }
      }
    end
    let(:spreadsheet_filename) { '1_valid_rows.csv' }

    setup do
      SubmissionSerializer.construct!(submission_template_hash)
    end

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

  context 'an asset driven submission' do
    let(:spreadsheet_filename) { 'template_for_bulk_submission.csv' }
    let!(:asset) { create :plate, barcode: '111111', well_count: 1, well_factory: :untagged_well }
    let(:submission_template_hash) do
      {
        name: 'Example Template',
        submission_class_name: 'LinearSubmission',
        product_catalogue: 'Generic',
        submission_parameters: { request_options: { 'fragment_size_required_to' => '400',
                                                    'fragment_size_required_from' => '100' },
                                 request_types: request_types.map(&:key) }
      }
    end
    setup do
      SubmissionSerializer.construct!(submission_template_hash)
    end
    it { is_expected.to be_valid }
    it 'links the samples to the study' do
      check = false
      subject.process
      asset.contained_samples.each do |sample|
        check = true
        expect(sample.studies).to include(study)
      end
      expect(check).to be true # Ensure we have actually run our tests to prevent silent failure
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

  context 'a submission with bait libraries' do
    let(:spreadsheet_filename) { '2_valid_SC_submissions.csv' }
    let!(:bait_library) { create :bait_library, name: 'Bait library 1' }
    let!(:bait_library_2) { create :bait_library, name: 'Bait library 2' }

    let!(:submission_template) do
      create :limber_wgs_submission_template,
             name: 'Bait submission example',
             request_types: [request_type]
    end
    let(:request_type) { create(:isc_library_request_type) }

    let(:expected_request_options) do
      {
        'fragment_size_required_to' => '10',
        'fragment_size_required_from' => '1',
        'read_length' => '100',
        'bait_library_name' => 'Bait library 1',
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
