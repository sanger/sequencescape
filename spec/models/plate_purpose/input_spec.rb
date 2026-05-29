# frozen_string_literal: true

require 'rails_helper'

# This behaviour is necessary because of limitations in generic lims
# We can switch to the PlatePurpose::Input class once we're in limber
describe PlatePurpose::Input do
  let(:plate_purpose_input) { create(:input_plate_purpose) }
  let(:plate) { create(:plate, purpose: plate_purpose_input, well_count: 2, well_factory: :untagged_well) }

  describe '#state_of' do
    subject(:state_of) { plate_purpose_input.state_of(plate) }

    context 'with no requests' do
      it 'is pending' do
        expect(state_of).to eq('pending')
      end
    end

    context 'with a pending request on each well' do
      before { plate.wells.each { |well| create(:request_library_creation, asset: well) } }

      it 'is passed' do
        expect(state_of).to eq('passed')
      end
    end

    context 'with a failed request on each well' do
      before { plate.wells.each { |well| create(:request_library_creation, asset: well, state: 'failed') } }

      it 'is failed' do
        expect(state_of).to eq('failed')
      end
    end

    context 'with a cancelled request on each well' do
      before { plate.wells.each { |well| create(:request_library_creation, asset: well, state: 'cancelled') } }

      it 'is cancelled' do
        expect(state_of).to eq('cancelled')
      end
    end

    context 'with a mix of cancelled and failed requests' do
      before do
        create(:request_library_creation, asset: plate.wells.first, state: 'cancelled')
        create(:request_library_creation, asset: plate.wells.last, state: 'failed')
      end

      it 'is failed' do
        expect(state_of).to eq('failed')
      end
    end

    context 'with two active requests in each well' do
      before { plate.wells.each { |well| create_list(:request_library_creation, 2, asset: well) } }

      it 'is passed' do
        expect(state_of).to eq('passed')
      end
    end

    context 'when some wells with aliquots have no customer requests (partial submission)' do
      before do
        # Only one of the two wells gets a request, leaving the other with an aliquot but no request
        create(:request_library_creation, asset: plate.wells.first)
      end

      context 'when default_state is not set on the purpose' do
        it 'is passed' do
          expect(state_of).to eq('passed')
        end
      end

      context 'when default_state is set on the purpose and there are no requests' do
        let(:plate_purpose_input) { create(:input_plate_purpose, default_state: 'passed') }

        it 'returns the default_state' do
          expect(state_of).to eq('passed')
        end
      end
    end

    context 'with one pending request and one cancelled request in each well' do
      before do
        plate.wells.each do |well|
          create(:request_library_creation, asset: well)
          create(:request_library_creation, asset: well, state: 'cancelled')
        end
      end

      it 'is passed' do
        expect(state_of).to eq('passed')
      end
    end

    context 'with 2 cancelled requests in each well' do
      before do
        plate.wells.each do |well|
          create(:request_library_creation, asset: well, state: 'cancelled')
          create(:request_library_creation, asset: well, state: 'cancelled')
        end
      end

      it 'is cancelled' do
        expect(state_of).to eq('cancelled')
      end
    end
  end
end
