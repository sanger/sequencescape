# frozen_string_literal: true

require 'rails_helper'

describe Qcable do
  let(:lot) { create(:lot) }
  let(:qcable_creator) { create(:qcable_creator) }

  it 'can create an asset with a barcode' do
    qcable = described_class.create(qcable_creator:, lot:, barcode: 'CGAP-123456')
    expect(qcable.asset.barcodes.first.barcode).to eq('CGAP-123456')
  end
end
