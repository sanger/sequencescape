# frozen_string_literal: true

require 'rails_helper'

describe QcableCreator do
  let(:user) { create(:user) }
  let(:lot) { create(:tag2_lot) }

  it 'will create some qcables with a count' do
    qcable_creator = described_class.create(count: 10, user: user, lot: lot)
    expect(qcable_creator.qcables.count).to eq(10)
  end

  it 'will create some qcables with a list of barcodes' do
    barcodes = 'CGAP-1,CGAP-2,CGAP-3,CGAP-4,CGAP-5'
    qcable_creator = described_class.create(barcodes:, user:, lot:)
    expect(qcable_creator.qcables.count).to eq(5)
    expect(qcable_creator.qcables.first.barcodes.first.barcode).to eq('CGAP-1')
    expect(qcable_creator.qcables.last.barcodes.first.barcode).to eq('CGAP-5')
  end

  context 'with supplied plate barcode' do
    let(:plate_barcode) { create(:sequencescape22, barcode: 'SQPD-T1-12345-A') }
    let(:lot) { create(:tag_layout_lot) }

    it 'will create qcables with single barcode' do
      qcable_creator = described_class.create(user: user, lot: lot, supplied_barcode: plate_barcode)
      expect(qcable_creator.qcables.count).to eq(1)
      expect(qcable_creator.qcables.first.barcodes.count).to eq(1)
      expect(qcable_creator.qcables.first.barcodes.first).to eq(plate_barcode)
      expect(qcable_creator.qcables.first.asset.barcodes.count).to eq(1)
      expect(qcable_creator.qcables.first.asset.barcodes.first).to eq(plate_barcode)
      expect(qcable_creator.qcables.first.asset.primary_barcode).to eq(plate_barcode)
      expect(qcable_creator.qcables.first.asset.name).to eq("Plate #{plate_barcode.barcode}")
    end
  end
end
