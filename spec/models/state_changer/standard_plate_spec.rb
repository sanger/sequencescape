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
  let(:user) { build_stubbed(:user) }
  let(:contents) { [] }
  let(:customer_accepts_responsibility) { false }

  describe '#update_labware_state' do
    context 'when the plate is the initial plate in the pipeline' do
      include_context 'a limber target plate with submissions', 'pending'

      context 'when the target state is started' do
        let(:target_state) { 'started' }

        it 'starts the requests', :aggregate_failures do
          # Requests are started and we create one event per order.
          expect { state_changer.update_labware_state }.to change(BroadcastEvent::LibraryStart, :count).by(1)
          expect(library_requests).to all(be_started)
        end
      end

      # RVI BCL uses the processed_1 state as the first state for the the initial plate
      context 'when the target state is processed_1' do
        let(:target_state) { 'processed_1' }

        it 'starts the requests', :aggregate_failures do
          # Requests are started and we create one event per order.
          expect { state_changer.update_labware_state }.to change(BroadcastEvent::LibraryStart, :count).by(1)
          expect(library_requests).to all(be_started)
        end
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
      let(:target_plate) { create(:final_plate) }
      let(:library_requests) { target_plate.wells.flat_map(&:requests_as_target) }
      let(:target_state) { 'cancelled' }

      it 'does not cancel the requests', :aggregate_failures do
        expect { state_changer.update_labware_state }.not_to change(BroadcastEvent::LibraryStart, :count)
        expect(library_requests.each(&:reload)).to all(be_passed)
      end
    end

    context 'when the plate is failed at the end of the pipeline' do
      let(:target_plate) { create(:final_plate) }
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

      let(:tested_wells) { 2 }
      let(:target_state) { 'failed' }

      # override default target plate creation
      let(:target_plate) { create(:plate, well_count: 4) }
      let(:target_wells) { target_plate.wells.index_by(&:map_description) }

      before do
        parent_wells = input_plate.wells.index_by(&:map_description)

        source_well_a1_request = library_requests.detect { |r| r.source_well == parent_wells['A1'] }
        source_well_b1_request = library_requests.detect { |r| r.source_well == parent_wells['B1'] }

        # set up wells in target plate
        # A1, B1 and C1 created by transferring from parent A1 (1st library request)
        target_wells['A1'].stock_well_links << build(
          :stock_well_link,
          target_well: target_wells['A1'],
          source_well: parent_wells['A1']
        )
        create(
          :transfer_request,
          asset: parent_wells['A1'],
          target_asset: target_wells['A1'],
          outer_request: source_well_a1_request
        )

        target_wells['B1'].stock_well_links << build(
          :stock_well_link,
          target_well: target_wells['B1'],
          source_well: parent_wells['A1']
        )
        create(
          :transfer_request,
          asset: parent_wells['A1'],
          target_asset: target_wells['B1'],
          outer_request: source_well_a1_request
        )

        target_wells['C1'].stock_well_links << build(
          :stock_well_link,
          target_well: target_wells['C1'],
          source_well: parent_wells['A1']
        )
        create(
          :transfer_request,
          asset: parent_wells['A1'],
          target_asset: target_wells['C1'],
          outer_request: source_well_a1_request
        )

        # D1 created by transferring from parent B1 (2nd library request)
        target_wells['D1'].stock_well_links << build(
          :stock_well_link,
          target_well: target_wells['D1'],
          source_well: parent_wells['B1']
        )
        create(
          :transfer_request,
          asset: parent_wells['B1'],
          target_asset: target_wells['D1'],
          outer_request: source_well_b1_request
        )
      end

      context 'when the other wells are not failed' do
        # This well will be failed, but 2 other wells share the request
        let(:contents) { ['A1'] }

        it 'prevents failure of the request', :aggregate_failures do
          expect { state_changer.update_labware_state }.not_to change(BroadcastEvent::LibraryStart, :count)

          # No requests are failed
          expect(library_requests.each(&:reload)).to all(be_started)
        end
      end

      context 'when a related well is already failed, but one is still active' do
        # Well B1 will be failed, it shares a request with A1 that is already failed.
        let(:contents) { ['B1'] }

        before do
          # this fails the transfer request in A1 before the test, which results in well A1
          #  having state failed, but it does not fail the library request
          target_wells['A1'].transfer_requests_as_target.first.transition_to('failed')
        end

        it 'prevents failure of the request', :aggregate_failures do
          # check well A1 is in failed state as expected
          expect(target_wells['A1'].reload).to be_failed

          expect { state_changer.update_labware_state }.not_to change(BroadcastEvent::LibraryStart, :count)

          # No requests are failed
          expect(library_requests.each(&:reload)).to all(be_started)
        end
      end

      context 'when all other related wells are already failed' do
        # These wells will be failed, they both share a request with A1 that is already failed.
        let(:contents) { %w[B1 C1] }

        before do
          # this fails the request in A1, which results in well A1 having state failed
          target_wells['A1'].transfer_requests_as_target.first.transition_to('failed')
        end

        it 'fails the request', :aggregate_failures do
          # check well A1 is in failed state as expected
          expect(target_wells['A1'].reload).to be_failed

          expect { state_changer.update_labware_state }.not_to change(BroadcastEvent::LibraryStart, :count)

          # need to reload before checking request state
          library_requests.each(&:reload)

          # Request shared by A1, B1 and C1 should now be failed
          expect(library_requests[0]).to be_failed

          # D1 request should be unchanged
          expect(library_requests[1]).to be_started
        end
      end
    end
  end
end
