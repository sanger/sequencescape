# frozen_string_literal: true

require 'rails_helper'

describe UatActions::TestSubmission do
  context 'valid options' do
    before do
      expect(PlateBarcode).to receive(:create).and_return(build(:plate_barcode, barcode: 2))
    end

    let(:submission_template) { create :limber_wgs_submission_template }
    let(:parameters) { { submission_template_name: submission_template.name } }
    let(:uat_action) { described_class.new(parameters) }
    let(:report) do
      # A report is a hash of key value pairs which get returned to the user.
      # It should include information such as barcodes and identifiers
      { 'plate_barcode_0' => 'DN2T' }
    end

    it 'can be performed' do
      expect(uat_action.perform).to eq true
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
        expect(uat_action.perform).to eq true
        expect(uat_action.report['plate_barcode_0']).to eq report['plate_barcode_0']
        expect(uat_action.report['submission_id']).to be_a Integer
      end
    end
  end

  it 'returns a default' do
    expect(described_class.default).to be_a described_class
  end
end
