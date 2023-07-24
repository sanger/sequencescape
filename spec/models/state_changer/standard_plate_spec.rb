# frozen_string_literal: true

require 'spec_helper'
require 'shared_contexts/limber_shared_context'

RSpec.describe StateChanger::StandardPlate do
  let(:state_changer) do
    described_class.new(
      labware: target_plate,
      target_state: target_state,
      user: user,
      contents: contents,
      customer_accepts_responsibility: customer_accepts_responsibility
    )
  end
  let(:user) { build_stubbed :user }
  let(:contents) { [] }
  let(:customer_accepts_responsibility) { false }

  describe '#update_labware_state' do
    context 'when the plate is the initial plate in the pipeline' do
      include_context 'a limber target plate with submissions', 'pending'

      let(:target_state) { 'started' }

      it 'starts the requests', :aggregate_failures do
        # Requests are started and we create one event per order.
        expect { state_changer.update_labware_state }.to change(BroadcastEvent::LibraryStart, :count).by(1)
        expect(library_requests).to all(be_started)
      end
    end

    context 'when the plate is the initial plate in the pipeline but libraries are started' do
      include_context 'a limber target plate with submissions'

      let(:target_state) { 'started' }

      it 'starts the requests', :aggregate_failures do
        expect { state_changer.update_labware_state }.to change(BroadcastEvent::LibraryStart, :count).by(0)
      end
    end

    context 'when the plate is cancelled at the end of the pipeline' do
      let(:target_plate) { create :final_plate }
      let(:library_requests) { target_plate.wells.flat_map(&:requests_as_target) }
      let(:target_state) { 'cancelled' }

      it 'does not cancel the requests', :aggregate_failures do
        expect { state_changer.update_labware_state }.to change(BroadcastEvent::LibraryStart, :count).by(0)
        expect(library_requests.each(&:reload)).to all(be_passed)
      end
    end

    context 'when the plate is failed at the end of the pipeline' do
      let(:target_plate) { create :final_plate }
      let(:library_requests) { target_plate.wells.flat_map(&:requests_as_target) }
      let(:target_state) { 'failed' }

      it 'does allow failure of the requests', :aggregate_failures do
        expect { state_changer.update_labware_state }.to change(BroadcastEvent::LibraryStart, :count).by(0)
        expect(library_requests.each(&:reload)).to all(be_failed)
      end
    end

    context 'when the plate is failed in the middle of the pipeline' do
      include_context 'a limber target plate with submissions'
      let(:target_state) { 'failed' }

      it 'does allow failure of the requests', :aggregate_failures do
        expect { state_changer.update_labware_state }.to change(BroadcastEvent::LibraryStart, :count).by(0)
        expect(library_requests.each(&:reload)).to all(be_failed)
      end
    end

    context 'when the customer accepts responsibility' do
      include_context 'a limber target plate with submissions'
      let(:target_state) { 'failed' }
      let(:customer_accepts_responsibility) { true }

      it 'does allow failure of the requests', :aggregate_failures do
        expect { state_changer.update_labware_state }.to change(BroadcastEvent::LibraryStart, :count).by(0)
        reloaded_library_requests = library_requests.each(&:reload)
        expect(reloaded_library_requests).to all(be_failed)
        expect(reloaded_library_requests).to all(be_customer_accepts_responsibility)
      end
    end
  end
end
