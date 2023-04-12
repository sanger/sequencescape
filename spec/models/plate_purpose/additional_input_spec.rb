# frozen_string_literal: true

require 'rails_helper'

# This behaviour is in use for defining inputs that can be added in
# the middle of a workflow
describe PlatePurpose::AdditionalInput do
  let(:plate_purpose_input) { create(:purpose_additional_input) }

  it 'does not have any errors' do
    expect(plate_purpose_input.errors.messages.to_a).to eq([])
  end

  describe '#state_of' do
    subject(:state_of) { plate_purpose_input.state_of(plate) }

    let(:plate) { create :plate, :with_wells, well_count: 2, purpose: plate_purpose_input }

    context 'with no requests' do
      it 'is pending' do
        plate_purpose_input.validate
        expect(plate_purpose_input.errors.messages.to_a).to eq([])
        expect(state_of).to eq('pending')
      end
    end

    context 'with ancestors' do
      let(:parent_plate) { create :plate }
      let(:plate) { create(:target_plate, parent: parent_plate, purpose: plate_purpose_input) }

      context 'with no library requests' do
        it 'is pending' do
          plate_purpose_input.validate
          expect(plate_purpose_input.errors.messages.to_a).to eq([])
          expect(state_of).to eq('pending')
        end
      end

      context 'with library requests' do
        before do
          create(:library_creation_request, asset: plate.wells[0])
          create(:library_creation_request, asset: plate.wells[1])
        end

        it 'is pending' do
          plate_purpose_input.validate
          expect(plate_purpose_input.errors.messages.to_a).to eq([])
          expect(state_of).to eq('pending')
        end
      end
    end

    context 'with no ancestors' do
      let(:plate) { create :plate_with_untagged_wells, well_count: 2, purpose: plate_purpose_input }

      context 'with no library requests' do
        it 'is pending' do
          plate_purpose_input.validate
          expect(plate_purpose_input.errors.messages.to_a).to eq([])
          expect(state_of).to eq('pending')
        end
      end

      context 'with library requests' do
        before do
          create(:library_creation_request, asset: plate.wells[0])
          create(:library_creation_request, asset: plate.wells[1])
        end

        it 'is passed' do
          plate_purpose_input.validate
          expect(plate_purpose_input.errors.messages.to_a).to eq([])
          expect(state_of).to eq('passed')
        end
      end
    end
  end
end
