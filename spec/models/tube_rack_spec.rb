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
  end
end
