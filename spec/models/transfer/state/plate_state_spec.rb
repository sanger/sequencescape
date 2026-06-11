# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Transfer::State::PlateState do
  describe '.in_state' do
    # Three pairs of parent/child plates are created, with transfer requests flowing
    # from the parent wells into the child wells. Each pair has a distinct transfer
    # request state so that the in_state scope can be exercised in isolation.
    let(:parent_of_passed_plate) { create(:plate, well_count: 2) }
    let(:parent_of_failed_plate) { create(:plate, well_count: 2) }
    let(:parent_of_pending_plate) { create(:plate, well_count: 2) }

    let!(:passed_plate) { create(:plate_with_empty_wells, well_count: 2) }
    let!(:failed_plate) { create(:plate_with_empty_wells, well_count: 2) }
    let!(:pending_plate) { create(:plate_with_empty_wells, well_count: 2) }

    before do
      parent_of_passed_plate.wells.zip(passed_plate.wells).each do |source, target|
        create(:transfer_request, asset: source, target_asset: target, state: 'passed')
      end

      parent_of_failed_plate.wells.zip(failed_plate.wells).each do |source, target|
        create(:transfer_request, asset: source, target_asset: target, state: 'failed')
      end

      parent_of_pending_plate.wells.zip(pending_plate.wells).each do |source, target|
        create(:transfer_request, asset: source, target_asset: target, state: 'pending')
      end
    end

    context "when filtering by 'passed'" do
      subject(:result) { Plate.in_state('passed') }

      it 'returns plates whose transfer requests are in the passed state' do
        expect(result).to include(passed_plate)
      end

      it 'does not return plates in other states' do
        expect(result).not_to include(failed_plate, pending_plate)
      end
    end

    context "when filtering by 'failed'" do
      subject(:result) { Plate.in_state('failed') }

      it 'returns plates whose transfer requests are in the failed state' do
        expect(result).to include(failed_plate)
      end

      it 'does not return plates in other states' do
        expect(result).not_to include(passed_plate, pending_plate)
      end
    end

    context "when filtering by 'pending'" do
      subject(:result) { Plate.in_state('pending') }

      it 'returns plates whose transfer requests are in the pending state' do
        expect(result).to include(pending_plate)
      end

      it 'does not return plates in other states' do
        expect(result).not_to include(passed_plate, failed_plate)
      end
    end

    context 'when filtering by multiple states' do
      subject(:result) { Plate.in_state(%w[passed failed]) }

      it 'returns plates matching any of the specified states' do
        expect(result).to include(passed_plate, failed_plate)
      end

      it 'does not return plates not matching the specified states' do
        expect(result).not_to include(pending_plate)
      end
    end

    context 'when all valid states are passed' do
      it 'returns all plates without filtering by transfer request state' do
        expect(Plate.in_state(Transfer::State::ALL_STATES)).to include(passed_plate, failed_plate, pending_plate)
      end
    end

    context 'when a plate has multiple transfer requests (one per well)' do
      it 'does not return duplicate plates in the results' do
        # passed_plate has 2 wells, so 2 transfer requests target it — one per well.
        # The join in in_state produces one row per matching transfer request, so
        # without a DISTINCT the plate appears twice in the results.
        result = Plate.in_state('passed')
        expect(result.count { |p| p == passed_plate }).to eq(1)
      end
    end
  end
end
