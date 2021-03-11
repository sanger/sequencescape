# frozen_string_literal: true

require 'rails_helper'

describe BulkSubmission, with: :uploader do
  subject do
    described_class.new(spreadsheet: submission_file, encoding: encoding)
  end

  let(:encoding) { 'Windows-1252' }
  let(:spreadsheet_path) { Rails.root.join('features', 'submission', 'csv', spreadsheet_filename) }
  # NB. fixture_file_upload is a Rails method on ActionDispatch::TestProcess::FixtureFile
  let(:submission_file) { fixture_file_upload(spreadsheet_path) }

  let(:number_submissions_created) { subject.completed_submissions.first.length }
  let(:generated_submissions) { Submission.find(subject.completed_submissions.first) }
  let(:generated_submission) { generated_submissions.first }
  let(:request_types) { create_list :well_request_type, 2 }

  after { submission_file.close }

  let!(:study) { create :study, name: 'abc123_study' }
  let!(:asset_group) { create :asset_group, name: 'assetgroup123', study: study, asset_count: 2 }
  let!(:library_type) { create :library_type, name: 'Standard' }

  before do
    create :user, login: 'user'
    create :project, name: 'Test project'
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
    let(:spreadsheet_filename) { '2_valid_sc_submissions.csv' }
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

  context 'a submission with a lowercase library type' do
    let(:spreadsheet_filename) { 'with_lowercase_library_type.csv' }

    let!(:submission_template) do
      create :limber_wgs_submission_template,
             name: 'library_type_test',
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

    it 'uses the database case sensitive library type name in the request options' do
      subject.process
      expect(generated_submission.orders.first.request_options).to eq(expected_request_options)
    end
  end

  context 'a submission with an unrecognised library type' do
    let(:spreadsheet_filename) { 'with_unknown_library_type.csv' }

    let!(:submission_template) do
      create :limber_wgs_submission_template,
             name: 'library_type_test',
             request_types: [request_type]
    end
    let(:request_type) { create(:library_request_type) }

    it 'is not valid' do
      # validation includes trying to process the file which errors due to unrecognised library type
      expect(subject).not_to be_valid
    end

    it 'sets an error message' do
      subject.process
      expect(subject.errors.messages[:spreadsheet][0]).to eq('There was a problem on row(s) 2: Cannot find library type "unrecognised"')
    end
  end
end
