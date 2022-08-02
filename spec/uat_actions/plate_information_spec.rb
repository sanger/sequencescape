# frozen_string_literal: true

require 'rails_helper'

describe UatActions::PlateInformation do
  context 'when the plate has aliquots' do
    let(:parameters) { { plate_barcode: 'SQPD-1' } }
    let(:uat_action) { described_class.new(parameters) }
    let(:report) do
      # A report is a hash of key value pairs which get returned to the user.
      # It should include information such as barcodes and identifiers
      { plate_barcode: 'SQPD-1', wells_with_aliquots: 'A1, B1, C1' }
    end

    before { create :plate_with_untagged_wells, sample_count: 3, barcode: 'SQPD-1' }

    it 'can be performed' do
      expect(uat_action.perform).to be true
      expect(uat_action.report).to eq report
    end
  end

  context 'when the plate is without aliquots' do
    let(:parameters) { { plate_barcode: 'SQPD-2' } }
    let(:uat_action) { described_class.new(parameters) }
    let(:report) do
      # A report is a hash of key value pairs which get returned to the user.
      # It should include information such as barcodes and identifiers
      { plate_barcode: 'SQPD-2', wells_with_aliquots: '' }
    end

    before { create :plate_with_empty_wells, well_count: 3, barcode: 'SQPD-2' }

    it 'can be performed' do
      expect(uat_action.perform).to be true
      expect(uat_action.report).to eq report
    end
  end

  context 'when the plate barcode does not match a plate' do
    let(:parameters) { { plate_barcode: 'INVALID' } }
    let(:uat_action) { described_class.new(parameters) }
    let(:report) do
      # A report is a hash of key value pairs which get returned to the user.
      # It should include information such as barcodes and identifiers
      { plate_barcode: 'INVALID' }
    end

    it 'cannot be performed' do
      expect(uat_action.perform).to be false
      expect(uat_action.report).to eq report
    end
  end

  it 'returns a default' do
    expect(described_class.default).to be_a described_class
  end
end
