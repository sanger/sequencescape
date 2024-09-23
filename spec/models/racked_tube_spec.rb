# frozen_string_literal: true

require 'rails_helper'
RSpec.describe RackedTube do
  describe '#create' do
    let!(:tube_rack) { create :tube_rack }
    let!(:tube) { create :tube }

    it 'allows a tube rack to be accessed from a tube' do
      racked_tube = described_class.create(tube_rack_id: tube_rack.id, tube_id: tube.id)

      result = described_class.find(racked_tube.id)
      expect(tube.racked_tube).to eq(result)
      expect(tube.tube_rack).to eq(tube_rack)
    end

    it 'allows a tube to be accessed from a tube rack' do
      racked_tube = described_class.create(tube_rack_id: tube_rack.id, tube_id: tube.id)

      result = described_class.find(racked_tube.id)
      expect(tube_rack.racked_tubes[0]).to eq(result)
      expect(tube_rack.tubes[0]).to eq(tube)
    end
  end

  describe '#update' do
    let!(:tube_rack) { create :tube_rack }
    let!(:tube) { create :tube }
    let!(:racked_tube) { described_class.create(tube_rack_id: tube_rack.id, tube_id: tube.id) }

    it 'can be updated' do
      racked_tube.update(coordinate: 'A1')

      expect(described_class.find(racked_tube.id).coordinate).to eq('A1')
    end
  end

  describe '#destroy' do
    let!(:tube_rack) { create :tube_rack }
    let!(:tube) { create :tube }
    let!(:racked_tube) { described_class.create(tube_rack_id: tube_rack.id, tube_id: tube.id) }

    it 'can be destroyed without affecting the tube or tube rack' do
      racked_tube.destroy

      expect(Tube.exists?(tube.id)).to be(true)
      expect(TubeRack.exists?(tube_rack.id)).to be(true)
    end
  end

  describe 'scope:: in_column_major_order' do
    let(:tube_rack) { create :tube_rack }
    let(:num_tubes) { locations.length }
    let(:locations) { %w[A01 H12 D04] }
    let(:barcodes) { Array.new(num_tubes) { create :fluidx } }

    before do
      Array.new(num_tubes) do |i|
        create(:sample_tube, :in_a_rack, tube_rack:, coordinate: locations[i], barcodes: [barcodes[i]])
      end
    end

    it 'sorts the racked tubes in column order' do
      expect(tube_rack.racked_tubes.in_column_major_order.map(&:coordinate)).to eq(%w[A01 D04 H12])
    end
  end
end
