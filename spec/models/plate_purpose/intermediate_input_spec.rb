# frozen_string_literal: true

require 'rails_helper'

# This behaviour is in use for defining inputs that can be added in
# the middle of a workflow
describe PlatePurpose::IntermediateInput do
  before do
    @plate_purpose_input = create(:purpose_intermediate_input)
  end

  describe '#state_of' do
    context 'with no requests' do
      it 'is pending' do
        plate = create :plate, :with_wells, well_count: 2, purpose: @plate_purpose_input
        state_of = @plate_purpose_input.state_of(plate)
        expect(state_of).to eq('pending')
      end
    end

    context 'with ancestors' do
      before do
        @parent_plate = create(:plate)
        @plate = create(:target_plate, parent: @parent_plate, purpose: @plate_purpose_input)
      end
      context 'with no library requests' do
        it 'is pending' do
          state_of = @plate_purpose_input.state_of(@plate)
          expect(state_of).to eq('pending')
        end
      end

      context 'with library requests' do
        before do
          create(:library_creation_request, asset: @plate.wells[0])
          create(:library_creation_request, asset: @plate.wells[1])
        end

        it 'is pending' do
          state_of = @plate_purpose_input.state_of(@plate)
          expect(state_of).to eq('pending')
        end
      end
    end

    context 'with no ancestors' do
      before do
        @plate = create(:plate_with_untagged_wells, well_count: 2, purpose: @plate_purpose_input)
      end

      context 'with no library requests' do
        it 'is pending' do
          state_of = @plate_purpose_input.state_of(@plate)
          expect(state_of).to eq('pending')
        end
      end

      context 'with library requests' do
        before do
          create(:library_creation_request, asset: @plate.wells[0])
          create(:library_creation_request, asset: @plate.wells[1])
        end

        it 'is passed' do
          state_of = @plate_purpose_input.state_of(@plate)
          expect(state_of).to eq('passed')
        end
      end
    end
  end
end
