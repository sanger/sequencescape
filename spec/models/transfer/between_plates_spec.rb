# frozen_string_literal: true

require 'rails_helper'

describe Transfer::BetweenPlates do
  let(:user) { create(:user) }
  let(:source) { create(:stock_plate, sample_count: 5, well_factory: :untagged_well) }
  let(:destination) { create(:plate, well_count: 5, well_factory: :empty_well) }

  before do
    described_class.create!(
      source: source,
      destination: destination,
      user: user,
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

  context 'with pre-capture pools' do
    # This test checks the fix that allows creating the BGE Lib PrePool plate
    # from BGE Lib PCR XP plate when some wells are failed in Limber. Failed
    # wells are skipped as long as they are not in the transfers specified.
    let(:plate) do
      plate = create(:pooling_plate) # 6 wells
      pools = [%w[A1 B1 C1], %w[D1 E1 F1]] # into 2 pools
      pools.each_with_index do |locations, index|
        plate
          .wells
          .located_at(locations)
          .each do |well|
            # likely to be after ISC submission
            create(:isc_request, asset: well, pre_capture_pool: pre_capture_pools[index])
          end
      end
      plate
    end
    let(:pre_capture_pools) { create_list(:pre_capture_pool, 2) }
    let(:child) { create(:plate_with_empty_wells) }
    # In the following, A1 is excluded from the input 'transfers' given by
    # Limber because it is failed. Sequencescape should exclude it from the
    # transfer request creation.
    let(:transfers) { { 'B1' => 'A1', 'C1' => 'A1', 'D1' => 'B1', 'E1' => 'B1', 'F1' => 'B1' } }

    it 'skips well that is not in transfers' do
      expect do
        described_class.create!(source: plate, destination: child, user: user, transfers: transfers)
      end.not_to raise_error

      expect(child.transfer_requests.size).to eq(5)
      expect(child.transfer_requests.map(&:asset)).to match_array(plate.wells.located_at(%w[B1 C1 D1 E1 F1]))
      expect(child.transfer_requests.map(&:target_asset).uniq).to match_array(child.wells.located_at(%w[A1 B1]))
    end
  end
end
