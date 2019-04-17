# frozen_string_literal: true

require 'rails_helper'

describe QcableCreator do
  let(:user) { create(:user) }
  let(:lot) { create(:tag2_lot) }

  it 'will create some qcables with a count' do
    qcable_creator = QcableCreator.create(count: 10, user: user, lot: lot)
    expect(qcable_creator.qcables.count).to eq(10)
  end

  it 'will create some qcables with a list of barcodes' do
    barcodes = 'CGAP-1,CGAP-2,CGAP-3,CGAP-4,CGAP-5'
    qcable_creator = QcableCreator.create(barcodes: barcodes, user: user, lot: lot)
    expect(qcable_creator.qcables.count).to eq(5)
    expect(qcable_creator.qcables.first.barcodes.first.barcode).to eq('CGAP-1')
    expect(qcable_creator.qcables.last.barcodes.first.barcode).to eq('CGAP-5')
  end
end
