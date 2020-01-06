# frozen_string_literal: true

require 'rails_helper'
RSpec.describe TubeRack do
  describe '#create' do
    it 'can be created' do
      tube_rack = create :tube_rack

      expect(described_class.exists?(tube_rack.id)).to eq(true)
    end

    it 'can contain racked_tubes' do
      tube_rack = create :tube_rack
      racked_tube = create :racked_tube

      expect { tube_rack.racked_tubes << racked_tube }.to(
        change { tube_rack.racked_tubes.count }.by(1)
      )
    end

    it 'can contain a barcode' do
      tube_rack = create :tube_rack
      barcode = create :barcode, barcode: 'SA00057843'

      tube_rack.barcodes << barcode

      expect(tube_rack.barcodes.last).to eq(barcode)
    end
  end

  describe '#update' do
    it 'can be updated' do
      tube_rack = create :tube_rack
      tube_rack.update(size: 96)

      expect(described_class.find(tube_rack.id).size).to eq(96)
    end
  end

  describe '#destroy' do
    let!(:tube_rack) { create :tube_rack }

    it 'can be destroyed' do
      tube_rack.destroy

      expect(described_class.exists?(tube_rack.id)).to eq(false)
    end

    it 'destroys the RackedTubes when destroyed' do
      tube = Tube.create
      racked_tube = tube_rack.racked_tubes.create(tube_id: tube.id)

      tube_rack.destroy

      expect(RackedTube.exists?(racked_tube.id)).to eq(false)
      expect(Tube.exists?(tube.id)).to eq(true)
    end
  end

  describe 'scope #contained_samples' do
    let(:num_tubes) { locations.length }
    let(:tube_rack) { create :tube_rack }
    let(:locations) { %w[A01 B01 C01] }
    let(:barcodes) { Array.new(num_tubes) { create :fluidx } }
    let!(:tubes) do
      Array.new(num_tubes) do |i|
        create(:sample_tube, :in_a_rack,
               tube_rack: tube_rack, coordinate: locations[i], barcodes: [barcodes[i]])
      end
    end

    it 'returns the samples of the tubes contained in the rack' do
      expect(tube_rack.contained_samples.to_a.sort).to eq(tubes.map(&:samples).flatten.sort)
    end
  end
end
