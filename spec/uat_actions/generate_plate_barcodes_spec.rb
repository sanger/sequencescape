# frozen_string_literal: true

require 'rails_helper'

describe UatActions::GeneratePlateBarcodes do
  context 'with valid options' do
    let(:uat_action) { described_class.new(number_of_barcodes_to_generate: '2') }

    before do
      allow(PlateBarcode).to receive(:create_barcode).and_return(
        build(:plate_barcode, barcode: 'SQPD-1'),
        build(:plate_barcode, barcode: 'SQPD-2')
      )
    end

    it 'can be performed' do
      expect(uat_action.perform).to be true
    end

    it 'reports the generated barcodes' do
      uat_action.perform
      expect(uat_action.report).to eq('barcodes' => %w[SQPD-1 SQPD-2])
    end
  end

  context 'with invalid options' do
    it 'is invalid with zero barcodes' do
      expect(described_class.new(number_of_barcodes_to_generate: '0')).not_to be_valid
    end
  end

  it 'returns a default' do
    expect(described_class.default).to be_a described_class
  end
end
