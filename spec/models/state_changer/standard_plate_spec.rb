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
        expect { state_changer.update_labware_state }.not_to change(BroadcastEvent::LibraryStart, :count)
      end
    end

    context 'when the plate is cancelled at the end of the pipeline' do
      let(:target_plate) { create :final_plate }
      let(:library_requests) { target_plate.wells.flat_map(&:requests_as_target) }
      let(:target_state) { 'cancelled' }

      it 'does not cancel the requests', :aggregate_failures do
        expect { state_changer.update_labware_state }.not_to change(BroadcastEvent::LibraryStart, :count)
        expect(library_requests.each(&:reload)).to all(be_passed)
      end
    end

    context 'when the plate is failed at the end of the pipeline' do
      let(:target_plate) { create :final_plate }
      let(:library_requests) { target_plate.wells.flat_map(&:requests_as_target) }
      let(:target_state) { 'failed' }

      it 'does allow failure of the requests', :aggregate_failures do
        expect { state_changer.update_labware_state }.not_to change(BroadcastEvent::LibraryStart, :count)
        expect(library_requests.each(&:reload)).to all(be_failed)
      end
    end

    context 'when the plate is failed in the middle of the pipeline' do
      include_context 'a limber target plate with submissions'
      let(:target_state) { 'failed' }

      it 'does allow failure of the requests', :aggregate_failures do
        expect { state_changer.update_labware_state }.not_to change(BroadcastEvent::LibraryStart, :count)
        expect(library_requests.each(&:reload)).to all(be_failed)
      end
    end

    context 'when the customer accepts responsibility' do
      include_context 'a limber target plate with submissions'
      let(:target_state) { 'failed' }
      let(:customer_accepts_responsibility) { true }

      it 'does allow failure of the requests', :aggregate_failures do
        expect { state_changer.update_labware_state }.not_to change(BroadcastEvent::LibraryStart, :count)
        reloaded_library_requests = library_requests.each(&:reload)
        expect(reloaded_library_requests).to all(be_failed)
        expect(reloaded_library_requests).to all(be_customer_accepts_responsibility)
      end
    end

    context 'when a specific well is failed' do
      include_context 'a limber target plate with submissions'
      let(:target_state) { 'failed' }
      let(:contents) { ['A1'] } # This is the well that will be failed

      it 'allows failure of the specified requests', :aggregate_failures do
        expect { state_changer.update_labware_state }.not_to change(BroadcastEvent::LibraryStart, :count)
        reloaded_library_requests = library_requests.each(&:reload)

        # A1 request should be failed
        expect(reloaded_library_requests.first).to be_failed

        # Other requests in B1 and C1 should be unchanged
        expect([reloaded_library_requests[1], reloaded_library_requests.last]).to all(be_started)
      end
    end

    context 'when a specific well is failed but the request is shared by other wells' do
      include_context 'a limber target plate with submissions'
      let(:target_state) { 'failed' }
      let(:samples) { create_list :sample, 2 }
      let(:study) { create :study, samples: samples }

      let(:request1) do
        create :library_request, asset: input_plate.wells[0], submission: target_submission, state: 'started'
      end
      let(:request2) do
        create :library_request, asset: input_plate.wells[1], submission: target_submission, state: 'started'
      end

      let(:aliquot1) { create :aliquot, sample: samples[0], request: request1 }
      let(:aliquot2) { create :aliquot, sample: samples[0], request: request1 }
      let(:aliquot3) { create :aliquot, sample: samples[1], request: request2 }

      let(:well1) { create :tagged_well, aliquots: [aliquot1] }
      let(:well2) { create :tagged_well, aliquots: [aliquot2] }
      let(:well3) { create :tagged_well, aliquots: [aliquot3] }

      let(:target_wells) { [well1, well2, well3] }

      let(:target_plate) { create :target_plate, parent: input_plate, well_count: 3, submission: target_submission }

      before { target_plate.wells = target_wells }

      context 'when the other wells are not failed' do
        let(:contents) { ['A1'] } # This well will be failed, but another well shares the request

        it 'prevents failure of the request', :aggregate_failures do
          expect { state_changer.update_labware_state }.not_to change(BroadcastEvent::LibraryStart, :count)

          # No requests are failed
          expect(library_requests.each(&:reload)).to all(be_started)
        end
      end

      context 'when the other wells are also failed' do
        # This well will be failed, it shares a request with B1 that is already failed.
        let(:contents) { ['A1'] }

        before { well2.update!(state: 'failed') }

        it 'fails the request', :aggregate_failures do
          expect { state_changer.update_labware_state }.not_to change(BroadcastEvent::LibraryStart, :count)
          reloaded_library_requests = library_requests.each(&:reload)

          # A1 request should be failed
          expect(reloaded_library_requests.first).to be_failed

          # Requests in C1 should be unchanged
          expect(reloaded_library_requests.last).to be_started
        end
      end
    end
  end
end
