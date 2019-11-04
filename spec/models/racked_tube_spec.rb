# frozen_string_literal: true

require 'rails_helper'
RSpec.describe RackedTube do
  describe '#create' do
    let!(:tube_rack) { create :tube_rack }
    let!(:tube) { create :tube }

    it 'can link a tube to a tube rack' do
      racked_tube = described_class.create(tube_rack_id: tube_rack.id, tube_id: tube.id)

      result = described_class.find(racked_tube.id)
      expect(tube_rack.racked_tubes[0]).to eq(result)
      expect(tube.racked_tube).to eq(result)
      expect(tube_rack.tubes[0]).to eq(tube)
      expect(tube.tube_rack).to eq(tube_rack)
    end
  end

  describe '#update' do
    let!(:tube_rack) { create :tube_rack }
    let!(:tube) { create :tube }
    let!(:racked_tube) { described_class.create(tube_rack_id: tube_rack.id, tube_id: tube.id) }

    it 'can be updated' do
      racked_tube.update(coordinate: "A1")

      expect(described_class.find(racked_tube.id).coordinate).to eq("A1")
    end
  end

  describe '#destroy' do
    let!(:tube_rack) { create :tube_rack }
    let!(:tube) { create :tube }
    let!(:racked_tube) { described_class.create(tube_rack_id: tube_rack.id, tube_id: tube.id) }

    it 'can be destroyed without affecting the tube or tube rack' do
      racked_tube.destroy
      
      expect(Tube.exists?(tube.id)).to eq(true)
      expect(TubeRack.exists?(tube_rack.id)).to eq(true)
    end
  end
end
