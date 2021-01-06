# frozen_string_literal: true

require 'rails_helper'
require 'prime'

RSpec.configure do |c|
  c.include LabWhereClientHelper
end

RSpec.describe CherrypickTask::ControlLocator, type: :model do
  let(:batch_id) { 1 }
  let(:available_positions) { [0, 1, 2, 3, 4, 5, 6] }
  let(:number_available_wells) { available_positions.length }

  let(:instance) { described_class.new(batch_id, number_available_wells) }

  describe '#control_positions_for_plate' do
    let(:available_positions) { [0, 1, 2, 3, 4, 5, 6] }
    let(:initial_positions) { [0, 4, 2] }

    context 'when is the initial plate' do
      it 'returns the initial positions' do
        expect(instance.control_positions_for_plate(0, initial_positions, available_positions)).to eq(initial_positions)
      end
    end

    context 'when is any other plate' do
      it 'returns the subsequent position from all initial positions', aggregate_failures: true do
        expect(instance.control_positions_for_plate(1, initial_positions, available_positions)).to eq([4, 1, 6])
        expect(instance.control_positions_for_plate(2, initial_positions, available_positions)).to eq([1, 5, 3])
        expect(instance.control_positions_for_plate(3, initial_positions, available_positions)).to eq([5, 2, 0])
      end
    end
  end

  describe '#per_plate_offset' do
    it 'always returns a number that is a prime (or 1), and not a factor of the plate size' do
      1.upto(1536).all? do |i|
        offset = instance.per_plate_offset(i)
        offset == 1 ||
          Prime.prime?(offset) && i % offset != 0
      end
    end
  end

  describe '#random_elements_from_list' do
    context 'with same seed' do
      it 'gets always the same result' do
        expect(instance.random_elements_from_list((0..96).to_a, 3, 3)).to(
          eq(instance.random_elements_from_list((0..96).to_a, 3, 3))
        )
      end
    end

    context 'with different seed' do
      it 'gives a different result' do
        expect(instance.random_elements_from_list((0..96).to_a, 3, 3)).not_to(
          eq(instance.random_elements_from_list((0..96).to_a, 3, 4))
        )
      end
    end
  end

  describe '#control_positions' do
    context 'when all inputs are right' do
      let(:random_list) { [25, 9, 95] }

      before do
        allow(instance).to receive(:random_elements_from_list).and_return(random_list)
      end

      it 'calculates the positions for the control wells', aggregate_failures: true do
        # Test batch id 0, plate 0 to 4, 5 free wells, 2 control wells
        expect(instance.control_positions(0, 0, 96, 3)).to eq(random_list)
        expect(instance.control_positions(0, 1, 96, 3)).to eq([78, 62, 52])
        expect(instance.control_positions(0, 2, 96, 3)).to eq([35, 19, 9])
      end
    end

    context 'when there are more controls than available positions' do
      it 'raises an error' do
        expect { instance.control_positions(0, 0, 2, 3) }.to raise_error(StandardError)
        expect { instance.control_positions(0, 0, 96, 97) }.to raise_error(StandardError)
        expect { instance.control_positions(0, 0, 96, 8, wells_to_leave_free: 89) }.to raise_error(StandardError)
        expect { instance.control_positions(0, 0, 96, 8, wells_to_leave_free: 88) }.not_to raise_error
      end
    end

    context 'with different arguments' do
      context 'when checking the call for #random_elements_from_list' do
        before do
          allow(instance).to receive(:random_elements_from_list).and_return([0, 1, 2])
        end

        it 'uses the right arguments' do
          expect(instance).to receive(:random_elements_from_list).with([0, 1, 2, 3, 4], 3, 0)
          instance.control_positions(0, 0, 5, 3)
          expect(instance).to receive(:random_elements_from_list).with([2, 3, 4], 3, 0)
          instance.control_positions(0, 0, 5, 3, wells_to_leave_free: 2)
        end

        context 'when num plate exceeds available positions' do
          it 'changes the seed' do
            expect(instance).to receive(:random_elements_from_list).with([0, 1, 2, 3, 4], 3, 66)
            instance.control_positions(33, 5, 5, 3)
            expect(instance).to receive(:random_elements_from_list).with([0, 1, 2, 3, 4], 3, 99)
            instance.control_positions(33, 10, 5, 3)
          end
        end
      end

      context 'when checking the call for #control_positions_for_plate' do
        before do
          allow(instance).to receive(:random_elements_from_list).and_return([1, 4, 3])
          allow(instance).to receive(:control_positions_for_plate)
        end

        it 'uses the right arguments' do
          expect(instance).to receive(:control_positions_for_plate).with(0, [1, 4, 3], [0, 1, 2, 3, 4])
          instance.control_positions(0, 0, 5, 3)
          expect(instance).to receive(:control_positions_for_plate).with(3, [1, 4, 3], [1, 2, 3, 4])
          instance.control_positions(0, 3, 5, 3, wells_to_leave_free: 1)
        end
      end
    end

    it 'fails when you try to put more controls than free wells' do
      # Test batch id 0, plate 0, 2 free wells, 3 control wells, so they dont fit
      expect do
        instance.control_positions(0, 0, 2, 3)
      end.to raise_error(StandardError, 'More controls than free wells')
    end

    it 'gets the same result with same batch and num plate' do
      expect(instance.control_positions(12345, 0, 100, 3)).to(
        eq(instance.control_positions(12345, 0, 100, 3))
      )
    end

    it 'does not get same result with a different plate in same batch' do
      expect(instance.control_positions(12345, 0, 100, 3)).not_to(
        eq(instance.control_positions(12345, 1, 100, 3))
      )
    end

    it 'does not get the same result with a different batch' do
      expect(instance.control_positions(12345, 0, 100, 3)).not_to(
        eq(instance.control_positions(12346, 0, 100, 3))
      )
    end

    context 'when num plate is higher than available positions' do
      it 'does not get same result with a different plate in same batch' do
        expect(instance.control_positions(12345, 0, 100, 3)).not_to(
          eq(instance.control_positions(12345, 100, 100, 3))
        )
      end

      it 'does not get the same result with a different batch' do
        expect(instance.control_positions(12345, 0, 100, 3)).not_to(
          eq(instance.control_positions(12346, 100, 100, 3))
        )
      end
    end

    it 'does not place controls in the first three columns for a 96-well destination plate' do
      # positions 0 - 24
      positions = instance.control_positions(12345, 0, 96, 3, wells_to_leave_free: 24)
      expect(positions).to(be_all { |p| p >= 24 })
    end
  end
end
