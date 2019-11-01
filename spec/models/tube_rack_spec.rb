# frozen_string_literal: true

require 'rails_helper'
RSpec.describe TubeRack do
  describe '#create' do
    it 'can contains racked_tubes' do
      tube_rack = create :tube_rack
      racked_tube = create :racked_tube

      expect { tube_rack.racked_tubes << racked_tube }.to(
        change { tube_rack.racked_tubes.count }.by(1)
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
