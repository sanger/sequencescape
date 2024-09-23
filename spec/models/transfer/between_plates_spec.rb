# frozen_string_literal: true

require 'rails_helper'

describe Transfer::BetweenPlates do
  let(:user) { create :user }
  let(:source) { create :stock_plate, sample_count: 5, well_factory: :untagged_well }
  let(:destination) { create :plate, well_count: 5, well_factory: :empty_well }

  before do
    described_class.create!(
      source:,
      destination:,
      user:,
      transfers: {
        'A1' => 'A1',
        'B1' => 'B1',
        'C1' => 'C1',
        'D1' => 'D1',
        'E1' => 'E1'
      }
    )
  end

  %w[A1 B1 C1 D1 E1].each do |location|
    it "creates transfers from #{location} to #{location}" do
      source_well = source.wells.located_at(location).first
      destination_well = destination.wells.located_at(location).first
      expect(source_well.transfer_requests_as_source.length).to eq(1)
      expect(source_well.transfer_requests_as_source.first.target_asset).to eq(destination_well)
      expect(destination_well.aliquots.first.sample_id).to eq(source_well.aliquots.first.sample_id)
      expect(destination_well.stock_wells).to eq([source_well])
    end
  end
end
