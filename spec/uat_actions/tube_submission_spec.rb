# frozen_string_literal: true

require 'rails_helper'

describe UatActions::TubeSubmission do
  context 'with valid options' do
    let(:tube) { create(:sample_tube, purpose: create(:sample_tube_purpose)) }
    let(:tube_barcode) { tube.barcodes.last.barcode }
    let(:submission_template) { create(:pbmc_pooling_submission_template) }
    let(:parameters) { { submission_template_name: submission_template.name, tube_barcodes: tube_barcode } }
    let(:uat_action) { described_class.new(parameters) }
    let(:report) do
      # A report is a hash of key value pairs which get returned to the user.
      # It should include information such as barcodes and identifiers
      { 'tube_barcodes' => [tube_barcode] }
    end

    it 'can be performed' do
      expect(uat_action.perform).to be true
      expect(uat_action.report['tube_barcodes']).to eq report['tube_barcodes']
      expect(uat_action.report['submission_id']).to be_a Integer
    end

    context 'with optional library type supplied' do
      let(:parameters) do
        {
          submission_template_name: submission_template.name,
          tube_barcodes: tube_barcode,
          library_type_name: 'Standard'
        }
      end

      it 'can be performed' do
        expect(uat_action.perform).to be true
        expect(uat_action.report['tube_barcodes']).to eq report['tube_barcodes']
        expect(uat_action.report['submission_id']).to be_a Integer
        expect(uat_action.report['library_type']).to eq 'Standard'
      end
    end

    context 'with optional number of pools supplied' do
      let(:number_of_pools) { 2 }
      let(:parameters) do
        {
          submission_template_name: submission_template.name,
          tube_barcodes: tube_barcode,
          number_of_pools: number_of_pools
        }
      end

      it 'can be performed' do
        expect(uat_action.perform).to be true
        expect(uat_action.report['tube_barcodes']).to eq report['tube_barcodes']
        expect(uat_action.report['submission_id']).to be_a Integer
        expect(uat_action.report['number_of_pools']).to eq number_of_pools
      end
    end

    context 'with optional cells per chip well supplied' do
      let(:num_cells) { 20_000 }
      let(:parameters) do
        {
          submission_template_name: submission_template.name,
          tube_barcodes: tube_barcode,
          cells_per_chip_well: num_cells
        }
      end

      it 'can be performed' do
        expect(uat_action.perform).to be true
        expect(uat_action.report['tube_barcodes']).to eq report['tube_barcodes']
        expect(uat_action.report['submission_id']).to be_a Integer
        expect(uat_action.report['cells_per_chip_well']).to eq num_cells
      end
    end
  end

  it 'returns a default' do
    expect(described_class.default).to be_a described_class
  end
end
