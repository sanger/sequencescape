# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Heron::Factories::Tube, heron: true, type: :model do
  let(:params) { { barcode: 'FD00000001' } }

  it 'is valid with all relevant attributes' do
    tube = described_class.new(params)
    expect(tube).to be_valid
  end

  it 'is not valid without a barcode' do
    tube = described_class.new(params.except(:barcode))
    expect(tube).not_to be_valid
  end

  it 'is not valid unless the barcode is unique in database for that format' do
    barcode = 'FD00000001'
    create(:barcode, barcode: barcode, asset: create(:sample_tube), format: Barcode.matching_barcode_format(barcode))
    tube = described_class.new(params)
    expect(tube).to be_invalid
  end

  describe '#create' do
    it 'persists the tube if it is valid' do
      tube = described_class.new(params)
      expect { tube.create }.to change(SampleTube, :count).by(1)
    end

    it 'creates a tube with the barcode specified' do
      tube = described_class.new(params)
      sample_tube = tube.create
      sample_tube.barcodes.reload
      expect(sample_tube.barcodes.count).to eq(2)
      expect(sample_tube.barcodes.last.barcode).to eq('FD00000001')
    end
  end
end
