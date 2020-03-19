# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Heron::Factories::Tube, type: :model, heron: true do

  let(:params) do
    {
       "barcode": "FD00000001",
       "supplier_sample_id": "PHEC-nnnnnnn1",
       "study": study
    }
  end

  let(:study) { create :study }

  it 'is valid with all relevant attributes' do
    tube = described_class.new(params)
    expect(tube).to be_valid
  end

  it 'is not valid without a barcode' do
    tube = described_class.new(params.except(:barcode))
    expect(tube).not_to be_valid
  end

  it 'is not valid without a supplier_sample_id' do
    tube = described_class.new(params.except(:supplier_sample_id))
    expect(tube).not_to be_valid
  end

  it 'is not valid unless the barcode is unique in database for that format' do
    barcode = 'FD00000001'
    format = Barcode.matching_barcode_format(barcode)
    asset = create(:sample_tube)
    create(:barcode, barcode: barcode, asset: asset, format: format)
    tube = described_class.new(params)
    expect(tube).to be_invalid
  end


  context '#create' do
    it 'persists the tube if it is valid' do
      tube = described_class.new(params)
      expect{
        tube.create
      }.to change{SampleTube.count}.by(1)
    end
    it 'persists the sample if it is valid' do
      tube = described_class.new(params)
      expect{
        tube.create
      }.to change{Sample.count}.by(1)
    end

    it 'creates a tube with the name as supplier_sample_id from MLWH' do
      tube = described_class.new(params)
      sample_tube = tube.create
      expect(sample_tube.samples.first.name).to eq("PHEC-nnnnnnn1")
    end

    it 'creates a tube with the public name as supplier_sample_id from MLWH' do
      tube = described_class.new(params)
      sample_tube = tube.create
      expect(sample_tube.samples.first.sample_metadata.sample_public_name).to eq("PHEC-nnnnnnn1")
    end

    it 'creates a tube with the supplier name as supplier_sample_id from MLWH' do
      tube = described_class.new(params)
      sample_tube = tube.create
      expect(sample_tube.samples.first.sample_metadata.supplier_name).to eq("PHEC-nnnnnnn1")
    end

    it 'creates a tube with the barcode specified' do
      tube = described_class.new(params)
      sample_tube = tube.create
      sample_tube.barcodes.reload
      expect(sample_tube.barcodes.count).to eq(2)
      expect(sample_tube.barcodes.last.barcode).to eq("FD00000001")
    end

  end



end
