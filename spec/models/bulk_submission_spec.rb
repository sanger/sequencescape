# frozen_string_literal: true

require 'rails_helper'

shared_examples 'an invalid scRNA Bulk Submission' do |_, tube_count|
  let(:request_types) { create_list(:sequencing_request_type, 2) }
  let!(:tubes) do
    create_list(:phi_x_stock_tube, tube_count) do |tube, i|
      tube.barcodes << Barcode.new(format: :sanger_ean13, barcode: "NT#{i + 1}")
    end
  end
  let!(:study) { create(:study, name: 'Test Study') }
  let!(:library_type) { create(:library_type, name: 'Standard') }

  let(:submission_template_hash) do
    {
      name: 'Limber-Htp - scRNA Core cDNA Prep GEM-X 5p',
      submission_class_name: 'LinearSubmission',
      product_catalogue: 'Generic',
      submission_parameters: {
        request_options: {
        },
        request_types: request_types.map(&:key)
      }
    }
  end

  before { SubmissionSerializer.construct!(submission_template_hash) }

  it 'is invalid' do
    expect { subject.process }.to raise_error(ActiveRecord::RecordInvalid)
  end
end

describe BulkSubmission, with: :uploader do
  subject { described_class.new(spreadsheet: submission_file, encoding: encoding) }

  let(:encoding) { 'Windows-1252' }
  let(:spreadsheet_path) { Rails.root.join('spec', 'data', 'submission', spreadsheet_filename) }

  # NB. fixture_file_upload is a Rails method on ActionDispatch::TestProcess::FixtureFile
  let(:submission_file) { fixture_file_upload(spreadsheet_path) }

  let(:number_submissions_created) { subject.completed_submissions.first.length }
  let(:generated_submissions) { Submission.find(subject.completed_submissions.first) }
  let(:generated_submission) { generated_submissions.first }
  let(:request_types) { create_list(:well_request_type, 2) }

  after { submission_file.close }

  let!(:study) { create(:study, name: 'abc123_study') }
  let!(:asset_group) { create(:asset_group, name: 'assetgroup123', study: study, asset_count: 2) }
  let!(:asset_group_2) { create(:asset_group, name: 'assetgroup2', study: study, asset_count: 1) }
  let!(:library_type) { create(:library_type, name: 'Standard') }

  before do
    create(:user, login: 'user')
    create(:project, name: 'Test project')
  end

  context 'a simple submission' do
    let(:submission_template_hash) do
      {
        name: 'Illumina-A - Cherrypick for pulldown - Pulldown WGS - HiSeq Paired end sequencing',
        submission_class_name: 'LinearSubmission',
        product_catalogue: 'Generic',
        superceeded_by_id: -2,
        submission_parameters: {
          info_differential: 5,
          request_options: {
            'fragment_size_required_to' => '400',
            'fragment_size_required_from' => '100'
          },
          request_types: request_types.map(&:key)
        }
      }
    end
    let(:spreadsheet_filename) { '1_valid_rows.csv' }

    before { SubmissionSerializer.construct!(submission_template_hash) }

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
    let!(:asset) { create(:plate, barcode: 'SQPD-1', well_count: 1, well_factory: :untagged_well) }
    let(:submission_template_hash) do
      {
        name: 'Example Template',
        submission_class_name: 'LinearSubmission',
        product_catalogue: 'Generic',
        submission_parameters: {
          request_options: {
            'fragment_size_required_to' => '400',
            'fragment_size_required_from' => '100'
          },
          request_types: request_types.map(&:key)
        }
      }
    end

    before { SubmissionSerializer.construct!(submission_template_hash) }

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
      create(:limber_wgs_submission_template, name: 'pcr_cycle_test', request_types: [request_type])
    end
    let(:request_type) { create(:library_request_type) }

    let(:expected_request_options) do
      {
        'fragment_size_required_to' => '400',
        'fragment_size_required_from' => '100',
        'pcr_cycles' => '5',
        'read_length' => '100',
        'library_type' => 'Standard',
        'multiplier' => {
          request_type.id.to_s => 1
        }
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
    let!(:primer_panel) { create(:primer_panel, name: 'Test panel') }

    let!(:submission_template) do
      create(:limber_wgs_submission_template, name: 'primer_panel_test', request_types: [request_type])
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
        'multiplier' => {
          request_type.id.to_s => 1
        }
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
    let!(:bait_library) { create(:bait_library, name: 'Bait library 1') }
    let!(:bait_library_2) { create(:bait_library, name: 'Bait library 2') }

    let!(:submission_template) do
      create(:limber_wgs_submission_template, name: 'Bait submission example', request_types: [request_type])
    end
    let(:request_type) { create(:isc_library_request_type) }

    let(:expected_request_options) do
      {
        'fragment_size_required_to' => '10',
        'fragment_size_required_from' => '1',
        'read_length' => '100',
        'bait_library_name' => 'Bait library 1',
        'multiplier' => {
          request_type.id.to_s => 1
        }
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
      create(:limber_wgs_submission_template, name: 'library_type_test', request_types: [request_type])
    end
    let(:request_type) { create(:library_request_type) }

    let(:expected_request_options) do
      {
        'fragment_size_required_to' => '400',
        'fragment_size_required_from' => '100',
        'pcr_cycles' => '5',
        'read_length' => '100',
        'library_type' => 'Standard',
        'multiplier' => {
          request_type.id.to_s => 1
        }
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
      create(:limber_wgs_submission_template, name: 'library_type_test', request_types: [request_type])
    end
    let(:request_type) { create(:library_request_type) }

    it 'is not valid' do
      # validation includes trying to process the file which errors due to unrecognised library type
      expect(subject).not_to be_valid
    end

    it 'sets an error message' do
      subject.process
      expect(subject.errors.messages[:spreadsheet][0]).to eq(
        'There was a problem on row(s) 2: Cannot find library type "unrecognised"'
      )
    end
  end

  context 'a submission with additional template name validations' do
    context 'when valid for scRNA template' do
      let(:submission_template_hash) do
        {
          name: 'Limber-Htp - scRNA Core cDNA Prep GEM-X 5p',
          submission_class_name: 'LinearSubmission',
          product_catalogue: 'Generic',
          submission_parameters: {
            request_options: {
            },
            request_types: request_types.map(&:key)
          }
        }
      end

      let(:spreadsheet_filename) { 'scrna_additional_validations_valid.csv' }

      before { SubmissionSerializer.construct!(submission_template_hash) }

      it 'is valid' do
        expect(subject).to be_valid
      end

      it 'generates submissions when processed' do
        subject.process
        expect(number_submissions_created).to eq(2)
      end

      it 'generates submissions with one order' do
        subject.process
        expect(generated_submission.orders.count).to eq(1)
      end
    end

    context 'when invalid for scRNA template on cells per chip well' do
      let(:submission_template_hash) do
        {
          name: 'Limber-Htp - scRNA Core cDNA Prep GEM-X 5p',
          submission_class_name: 'LinearSubmission',
          product_catalogue: 'Generic',
          submission_parameters: {
            request_options: {
            },
            request_types: request_types.map(&:key)
          }
        }
      end
      let(:spreadsheet_filename) { 'scrna_additional_validations_invalid_cells_per_chip_well.csv' }

      before { SubmissionSerializer.construct!(submission_template_hash) }

      it 'raises an error and sets an error message' do
        expect { subject.process }.to raise_error(ActiveRecord::RecordInvalid)
        expect(subject.errors.messages[:spreadsheet][0]).to eq(
          "Inconsistent values for column 'scrna core cells per chip well' for Study name 'abc123_study' " \
            "and Project name 'Test project', all rows for a specific study and project must have the same value"
        )
      end
    end

    context 'when an scRNA Bulk Submission for plate' do
      let!(:study) { create(:study, name: 'Test Study') }
      let!(:plate) { create(:plate_with_tagged_wells, sample_count: 96, barcode: 'SQPD-12345') }
      let!(:asset_group) { create(:asset_group, name: 'assetgroup', study: study, assets: plate.wells) }
      let!(:library_type) { create(:library_type, name: 'Standard') }
      let(:spreadsheet_filename) { 'scRNA_bulk_submission.csv' }
      let(:submission_template_hash) do
        {
          name: 'Limber-Htp - scRNA Core cDNA Prep GEM-X 5p',
          submission_class_name: 'LinearSubmission',
          product_catalogue: 'Generic',
          submission_parameters: {
            request_options: {
            },
            request_types: request_types.map(&:key)
          }
        }
      end

      before do
        SubmissionSerializer.construct!(submission_template_hash)
        # Assign a donor id to each sample
        plate.wells.each_with_index do |well, i|
          well.aliquots.first.sample.sample_metadata.update!(donor_id: "donor_#{i + 1}")
        end
      end

      it 'is valid' do
        expect(subject).to be_valid
      end

      it 'generates submissions when processed' do
        subject.process
        expect(number_submissions_created).to eq(1)
      end
    end

    context 'when an scRNA Bulk Submission for tubes' do
      let!(:request_types) { [create(:pbmc_pooling_customer_request_type)] }
      # Create a list of tubes with samples
      let!(:tubes) do
        Array.new(6) do |index|
          create(:sample_tube).tap do |tube|
            tube.barcodes << Barcode.new(format: :sanger_ean13, barcode: "NT#{index + 1}")
            tube.samples.first.sample_metadata.update!(donor_id: "donor_#{index}")
          end
        end
      end
      let!(:study) { create(:study, name: 'Test Study') }
      let!(:library_type) { create(:library_type, name: 'Standard') }

      let(:spreadsheet_filename) { 'scRNA_bulk_submission_tube.csv' }
      let(:submission_template_hash) do
        {
          name: 'Limber-Htp - scRNA Core cDNA Prep GEM-X 5p',
          submission_class_name: 'LinearSubmission',
          product_catalogue: 'Generic',
          submission_parameters: {
            request_options: {
            },
            request_types: request_types.map(&:key)
          }
        }
      end

      before { SubmissionSerializer.construct!(submission_template_hash) }

      it 'is valid' do
        expect(subject).to be_valid
      end

      it 'generates submissions when processed' do
        subject.process
        expect(number_submissions_created).to eq(1)
      end

      it 'adds the calculated allowance_band to the order request_options' do
        subject.process
        expect(generated_submission.orders[0].request_options).to have_key('allowance_band')
      end

      it 'calculates the allowance band correctly' do
        subject.process
        expect(generated_submission.orders[0].request_options['allowance_band']).to eq('Full allowance')
      end
    end

    context 'when an scRNA Bulk Submission given with invalid number of samples per pool' do
      context 'number of samples per pool < 5' do
        let(:spreadsheet_filename) { 'scRNA_bulk_submission_tube_invalid.csv' }

        include_examples 'an invalid scRNA Bulk Submission', 'scRNA_bulk_submission_tube_invalid', 4
      end

      context 'number of samples per pool > 25' do
        let(:spreadsheet_filename) { 'scRNA_bulk_submission_tube_invalid_greater.csv' }

        include_examples 'an invalid scRNA Bulk Submission', 'scRNA_bulk_submission_tube_invalid_greater', 32
      end
    end
  end
end
