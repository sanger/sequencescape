# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CherrypickTask::ControlLocator do
  let(:instance) do
    described_class.new(
      batch_id: batch_id,
      total_wells: total_wells,
      num_control_wells: num_control_wells,
      wells_to_leave_free: wells_to_leave_free,
      control_source_plate: create(:control_plate),
      template: create(:plate_template_with_well)
    )
  end

  shared_examples 'an invalid ControlLocator' do |plate_number, error = 'More controls than free wells'|
    it 'throws a "More controls than free wells" exception' do
      expect { instance.control_positions(plate_number) }.to raise_error(StandardError, error)
    end
  end

  shared_examples 'a generator of valid positions' do |valid_range|
    let(:generated_positions) do
      # Generate positions for a range of plates. This should be equal to the number
      # of wells we have available
      Array.new(valid_range.size) { |plate_number| instance.control_positions(plate_number) }
    end

    it 'generates positions within the range' do
      expect(generated_positions.flatten).to all(be_an(Integer) & be_in(valid_range))
    end

    it 'generates a unique position for each control' do
      # uniq! returns nil if there are no duplicate elements
      expect(generated_positions).to all(satisfy { |x| x.uniq!.nil? })
    end

    it "does not reuse positions within the first #{valid_range.size} plates" do
      expect(generated_positions.uniq!).to be_nil
    end

    it "resets the seed after #{valid_range.size} plates" do
      # NOTE: In practice we will expect this assertion to fail in some cases by chance.
      # The probability for any given batch is available_wells ^ number_of_controls.
      # As we seed the randomization from the batch id, these tests are deterministic,
      # but it is possible that future Ruby versions may change the behaviour of the prng
      # and this test may begin failing. If it does, we could:
      # * Just update this to ignore the problem batch
      # * Adjust the tested batch ranges
      # * Refactor this test to explicitly allow x% of tested batches to fail.
      expect(instance.control_positions(0)).not_to eq instance.control_positions(valid_range.size)
    end

    it 'allows easy identification of plate swaps' do
      # In order to allow identification of plate swaps we shift the control well location
      # for each plate in the batch. We do so by more than one well at a time
      generated_positions.each_cons(2) do |previous_plate, this_plate|
        this_plate.each_with_index { |position, index| expect(position).not_to be_within(5).of(previous_plate[index]) }
      end
    end

    it 'uses a control plate that is valid' do
      placement_type = instance.send(:control_placement_type)
      expect(placement_type.nil? || %w[fixed random].exclude?(placement_type)).to be_falsey
    end
  end

  # Control positions will be our only public method, sand perhaps some attr_readers
  # So we can focus on testing its behaviour, not implementation
  describe '#control_positions' do
    # Invalid contexts
    context 'when there are more control wells than total_wells' do
      let(:batch_id) { 1 }
      let(:total_wells) { 2 }
      let(:num_control_wells) { 3 }
      let(:wells_to_leave_free) { [] }

      it_behaves_like 'an invalid ControlLocator', 0
    end

    context 'when there are more control wells than available wells' do
      let(:batch_id) { 1 }
      let(:total_wells) { 96 }
      let(:num_control_wells) { 8 }
      let(:wells_to_leave_free) { (0...89) }

      it_behaves_like 'an invalid ControlLocator', 0
    end

    context 'when there are more wells left free than available' do
      let(:batch_id) { 1 }
      let(:total_wells) { 96 }
      let(:num_control_wells) { 0 }
      let(:wells_to_leave_free) { (0...100) }

      it_behaves_like 'an invalid ControlLocator', 0, 'More wells left free than available'
    end

    # Test the basics for a range of batches
    1.upto(1) do |batch_id| # SKIP batches 2-100 to reduce unneeeded tests
      context "when batch is #{batch_id} and we have a 96 well plate with no wells free" do
        let(:batch_id) { batch_id }
        let(:total_wells) { 96 }
        let(:num_control_wells) { 2 }
        let(:wells_to_leave_free) { [] }

        it_behaves_like 'a generator of valid positions', (0...96)
      end

      context "when batch is #{batch_id} and we have a 96 well plate with 8 wells free" do
        let(:batch_id) { batch_id }
        let(:total_wells) { 96 }
        let(:num_control_wells) { 2 }
        let(:wells_to_leave_free) { (0...8) }

        it_behaves_like 'a generator of valid positions', (8...96)
      end

      context "when batch is #{batch_id} and we have a 96 well plate with arbitary wells free" do
        let(:batch_id) { batch_id }
        let(:total_wells) { 96 }
        let(:num_control_wells) { 2 }
        let(:wells_to_leave_free) { [19, 79] }

        it_behaves_like 'a generator of valid positions', (0...96).to_a - [19, 79]
      end

      context "when batch is #{batch_id} and we have a 384 well plate with no wells free" do
        let(:batch_id) { batch_id }
        let(:total_wells) { 384 }
        let(:num_control_wells) { 2 }
        let(:wells_to_leave_free) { [] }

        it_behaves_like 'a generator of valid positions', (0...384)
      end
    end

    context 'when over a range of batches' do
      skip 'This analysis is not required to be run every time, so we skip it by default'

      let(:range) { (1...1000) }
      let(:control_positions) do
        range.map do |batch_id|
          described_class
            .new(
              batch_id: batch_id,
              total_wells: 96,
              num_control_wells: 1,
              control_source_plate: create(:control_plate),
              template: create(:plate_template)
            )
            .control_positions(0)
            .first
        end
      end

      it 'generates a reasonable control distribution' do
        # Counts up how many times each well is used
        tally = control_positions.tally

        # We expect all wells to be used
        expect(tally.length).to eq 96

        # At a reasonable distribution
        # Not sure how best to handle this one, we're effectively expecting
        # a binomial distribution. 25 is actually a pretty extreme outlier, and
        # 23 would be a more reasonable value. The actual data don't seem to smell
        # to much though... its well 61 that it over-represented, not 0 or 96 for instance.
        expect(tally.values).to all be_between(2, 25)
      end
    end

    context 'when the control placement type is not valid' do
      let(:batch_id) { 1 }
      let(:total_wells) { 96 }
      let(:num_control_wells) { 2 }
      let(:wells_to_leave_free) { [] }

      before { allow(instance).to receive(:control_placement_type).and_return('invalid_type') }

      it 'raises an error about invalid placement type' do
        expect { instance.control_positions(0) }.to raise_error(
          StandardError,
          'Control placement type is not set or is invalid'
        )
      end
    end

    context 'when the control plate and plate template are incompatible' do
      let(:batch_id) { 1 }
      let(:total_wells) { 96 }
      let(:num_control_wells) { 2 }
      let(:wells_to_leave_free) { [] }

      before do
        allow(instance).to receive_messages(
          control_placement_type: 'fixed',
          convert_assets: [1, 2, 3],
          control_source_plate: create(:control_plate)
        )
      end

      it 'returns and displays an error message' do
        expect(instance.handle_incompatible_plates).to be_truthy
      end
    end

    context 'when assets are converted using the maps' do
      let(:batch_id) { 1 }
      let(:total_wells) { 96 }
      let(:num_control_wells) { 2 }
      let(:wells_to_leave_free) { [] }

      before { allow(instance).to receive_messages(control_placement_type: 'fixed') }

      it 'they are given the correct position IDs' do
        expect(instance.send(:convert_assets, [94, 95, 96])).to eq([79, 87, 95])
      end
    end

    context 'when the control placement type is fixed' do
      let(:batch_id) { 1 }
      let(:total_wells) { 96 }
      let(:num_control_wells) { 2 }
      let(:wells_to_leave_free) { [] }

      before { allow(instance).to receive_messages(control_placement_type: 'fixed') }

      it 'passes as intended' do
        expect(instance.send(:fixed_positions_from_available)).to eq([])
      end
    end
  end
end
