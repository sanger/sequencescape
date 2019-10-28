# frozen_string_literal: true

require 'rails_helper'
RSpec.describe TubeRack do
  describe '#create' do
    it 'can contains rackable_tubes' do
      tube_rack = create :tube_rack
      rackable_tube = create :rackable_tube

      expect { tube_rack.rackable_tubes << rackable_tube }.to(
        change { tube_rack.rackable_tubes.count }.by(1)
      )
    end

    it 'can contain a barcode' do
      tube_rack = create :tube_rack
      barcode = create :barcode, barcode: '1234'

      tube_rack.barcodes << barcode

      expect(tube_rack.barcodes.first).to eq(barcode)
    end
  end
end
