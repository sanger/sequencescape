# frozen_string_literal: true

require 'rails_helper'

describe UatActions::TestSubmission do
  context 'valid options' do
    before { expect(PlateBarcode).to receive(:create_barcode).and_return(first_plate_barcode) }

    let(:submission_template) { create :limber_wgs_submission_template }
    let(:primer_panel) { create :primer_panel }
    let(:parameters) { { submission_template_name: submission_template.name } }
    let(:uat_action) { described_class.new(parameters) }
    let(:first_plate_barcode) { build(:plate_barcode) }
    let(:report) do
      # A report is a hash of key value pairs which get returned to the user.
      # It should include information such as barcodes and identifiers
      { 'plate_barcode_0' => first_plate_barcode[:barcode] }
    end

    it 'can be performed' do
      expect(uat_action.perform).to be true
      expect(uat_action.report['plate_barcode_0']).to eq report['plate_barcode_0']
      expect(uat_action.report['submission_id']).to be_a Integer
    end

    context 'with optional plate purpose supplied' do
      let(:parameters) do
        {
          submission_template_name: submission_template.name,
          plate_purpose_name: PlatePurpose.stock_plate_purpose.name
        }
      end

      it 'can be performed' do
        expect(uat_action.perform).to be true
        expect(uat_action.report['plate_barcode_0']).to eq report['plate_barcode_0']
        expect(uat_action.report['submission_id']).to be_a Integer
      end
    end

    context 'with optional library type supplied' do
      let(:parameters) { { submission_template_name: submission_template.name, library_type_name: 'Standard' } }

      it 'can be performed' do
        expect(uat_action.perform).to be true
        expect(uat_action.report['plate_barcode_0']).to eq report['plate_barcode_0']
        expect(uat_action.report['submission_id']).to be_a Integer
        expect(uat_action.report['library_type']).to eq 'Standard'
      end
    end

    context 'with optional primer panel supplied' do
      let(:parameters) do
        {
          submission_template_name: submission_template.name,
          library_type_name: 'Standard',
          primer_panel_name: 'Primer Panel 1'
        }
      end

      it 'can be performed' do
        expect(uat_action.perform).to be true
        expect(uat_action.report['plate_barcode_0']).to eq report['plate_barcode_0']
        expect(uat_action.report['submission_id']).to be_a Integer
        expect(uat_action.report['library_type']).to eq 'Standard'
        expect(uat_action.report['primer_panel']).to eq 'Primer Panel 1'
      end
    end

    context 'with optional number of wells with samples supplied' do
      let(:parameters) { { submission_template_name: submission_template.name, number_of_wells_with_samples: '2' } }

      it 'can be performed' do
        expect(uat_action.perform).to be true
        expect(uat_action.report['plate_barcode_0']).to eq report['plate_barcode_0']
        expect(uat_action.report['submission_id']).to be_a Integer
        expect(uat_action.report['number_of_wells_with_samples']).to be_a Integer
      end
    end

    context 'with optional number of wells to submit supplied' do
      let(:parameters) { { submission_template_name: submission_template.name, number_of_wells_to_submit: '2' } }

      it 'can be performed' do
        expect(uat_action.perform).to be true
        expect(uat_action.report['plate_barcode_0']).to eq report['plate_barcode_0']
        expect(uat_action.report['number_of_wells_to_submit']).to be_a Integer
      end
    end
  end

  it 'returns a default' do
    expect(described_class.default).to be_a described_class
  end
end
