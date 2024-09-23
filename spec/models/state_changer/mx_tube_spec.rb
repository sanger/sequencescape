# frozen_string_literal: true

# require 'rails_helper'
require 'spec_helper'

RSpec.describe StateChanger::MxTube do
  let(:state_changer) { described_class.new(labware:, target_state:, user:, customer_accepts_responsibility:) }

  let(:user) { build_stubbed :user }
  let(:customer_accepts_responsibility) { false }
  let(:labware) { create :multiplexed_library_tube }
  let(:transfer_request) { create :transfer_request, target_asset: labware.receptacle, state: transfer_request_state }
  let(:request) { create :request, target_asset: labware.receptacle, state: request_state, order: }
  let(:requests) { [request] }
  let(:order) { create :order }

  def create_requests_and_transfers
    transfer_request
    requests
  end

  before do
    create_requests_and_transfers
    state_changer.update_labware_state
  end

  context 'when the tube is: "pending"' do
    let(:transfer_request_state) { 'pending' }

    context 'when transitioning to "started" with "pending" requests' do
      let(:target_state) { 'started' }
      let(:request_state) { 'pending' }

      it 'updates the tube to "started" with "pending" requests', :aggregate_failures do
        expect(transfer_request.reload.state).to eq('started')
        expect(request.reload.state).to eq('pending')
      end
    end

    context 'when transitioning to "started" with "started" requests' do
      let(:target_state) { 'started' }
      let(:request_state) { 'started' }

      it 'updates the tube to "started" with "started" requests', :aggregate_failures do
        expect(transfer_request.reload.state).to eq('started')
        expect(request.reload.state).to eq('started')
      end
    end

    context 'when transitioning to "started" with "failed" requests' do
      let(:target_state) { 'started' }
      let(:request_state) { 'failed' }

      it 'updates the tube to "started" with "failed" requests', :aggregate_failures do
        expect(transfer_request.reload.state).to eq('started')
        expect(request.reload.state).to eq('failed')
      end
    end

    context 'when transitioning to "started" with "passed" requests' do
      let(:target_state) { 'started' }
      let(:request_state) { 'passed' }

      it 'updates the tube to "started" with "passed" requests', :aggregate_failures do
        expect(transfer_request.reload.state).to eq('started')
        expect(request.reload.state).to eq('passed')
      end
    end

    context 'when transitioning to "started" with "cancelled" requests' do
      let(:target_state) { 'started' }
      let(:request_state) { 'cancelled' }

      it 'updates the tube to "started" with "cancelled" requests', :aggregate_failures do
        expect(transfer_request.reload.state).to eq('started')
        expect(request.reload.state).to eq('cancelled')
      end
    end

    context 'when transitioning to "processed_1" with "pending" requests' do
      let(:target_state) { 'processed_1' }
      let(:request_state) { 'pending' }

      it 'updates the tube to "processed_1" with "pending" requests', :aggregate_failures do
        expect(transfer_request.reload.state).to eq('processed_1')
        expect(request.reload.state).to eq('pending')
      end
    end

    context 'when transitioning to "passed" with "failed" requests' do
      let(:target_state) { 'passed' }
      let(:request_state) { 'failed' }

      it 'updates the tube to "passed" with "failed" requests', :aggregate_failures do
        expect(transfer_request.reload.state).to eq('passed')
        expect(request.reload.state).to eq('failed')
      end
    end

    context 'when transitioning to "passed" with "passed" requests' do
      let(:target_state) { 'passed' }
      let(:request_state) { 'passed' }

      it 'updates the tube to "passed" with "passed" requests', :aggregate_failures do
        expect(transfer_request.reload.state).to eq('passed')
        expect(request.reload.state).to eq('passed')
      end
    end

    context 'when transitioning to "passed" with "cancelled" requests' do
      let(:target_state) { 'passed' }
      let(:request_state) { 'cancelled' }

      it 'updates the tube to "passed" with "cancelled" requests', :aggregate_failures do
        expect(transfer_request.reload.state).to eq('passed')
        expect(request.reload.state).to eq('cancelled')
      end
    end

    context 'when transitioning to "failed" with "started" requests' do
      let(:target_state) { 'failed' }
      let(:request_state) { 'started' }

      it 'updates the tube to "failed" with "failed" requests', :aggregate_failures do
        expect(transfer_request.reload.state).to eq('failed')
        expect(request.reload.state).to eq('failed')
      end
    end

    context 'when transitioning to "failed" with "passed" requests' do
      let(:target_state) { 'failed' }
      let(:request_state) { 'passed' }

      it 'updates the tube to "failed" with "passed" requests', :aggregate_failures do
        expect(transfer_request.reload.state).to eq('failed')
        expect(request.reload.state).to eq('passed')
      end
    end

    context 'when transitioning to "cancelled" with "pending" requests' do
      let(:target_state) { 'cancelled' }
      let(:request_state) { 'pending' }

      it 'updates the tube to "cancelled" with "pending" requests', :aggregate_failures do
        expect(transfer_request.reload.state).to eq('cancelled')
        expect(request.reload.state).to eq('pending')
      end
    end
  end

  context 'when the tube is: "processed_1"' do
    let(:transfer_request_state) { 'processed_1' }

    context 'when transitioning to "processed_2" with "started" requests' do
      let(:target_state) { 'processed_2' }
      let(:request_state) { 'started' }

      it 'updates the tube to "processed_2" with "started" requests', :aggregate_failures do
        expect(transfer_request.reload.state).to eq('processed_2')
        expect(request.reload.state).to eq('started')
      end
    end
  end

  context 'when the tube is: "started"' do
    let(:transfer_request_state) { 'started' }

    context 'when transitioning to "passed" with "started" requests' do
      let(:target_state) { 'passed' }
      let(:request_state) { 'started' }

      it 'updates the tube to "passed" with "passed" requests', :aggregate_failures do
        expect(transfer_request.reload.state).to eq('passed')
        expect(request.reload.state).to eq('passed')
      end
    end

    context 'when transitioning to "passed" with "failed" requests' do
      let(:target_state) { 'passed' }
      let(:request_state) { 'failed' }

      it 'updates the tube to "passed" with "failed" requests', :aggregate_failures do
        expect(transfer_request.reload.state).to eq('passed')
        expect(request.reload.state).to eq('failed')
      end
    end

    context 'when transitioning to "passed" with "cancelled" requests' do
      let(:target_state) { 'passed' }
      let(:request_state) { 'cancelled' }

      it 'updates the tube to "passed" with "cancelled" requests', :aggregate_failures do
        expect(transfer_request.reload.state).to eq('passed')
        expect(request.reload.state).to eq('cancelled')
      end
    end

    context 'when transitioning to "failed" with "started" requests' do
      let(:target_state) { 'failed' }
      let(:request_state) { 'started' }

      it 'updates the tube to "failed" with "failed" requests', :aggregate_failures do
        expect(transfer_request.reload.state).to eq('failed')
        expect(request.reload.state).to eq('failed')
      end
    end

    context 'when transitioning to "failed" with "passed" requests' do
      let(:target_state) { 'failed' }
      let(:request_state) { 'passed' }

      it 'updates the tube to "failed" with "passed" requests', :aggregate_failures do
        expect(transfer_request.reload.state).to eq('failed')
        expect(request.reload.state).to eq('passed')
      end
    end

    context 'when transitioning to "cancelled" with "pending" requests' do
      let(:target_state) { 'cancelled' }
      let(:request_state) { 'pending' }

      it 'updates the tube to "cancelled" with "pending" requests', :aggregate_failures do
        expect(transfer_request.reload.state).to eq('cancelled')
        expect(request.reload.state).to eq('pending')
      end
    end
  end

  context 'when the tube is: "failed"' do
    let(:transfer_request_state) { 'failed' }

    # Apparently we allow transitions to passed after failure.
    # However, this doesn't gel well with the test below
    context 'when transitioning to "passed" with "started" requests' do
      let(:target_state) { 'passed' }
      let(:request_state) { 'started' }

      it 'updates the tube to "passed" with "passed" requests', :aggregate_failures do
        expect(transfer_request.reload.state).to eq('passed')
        expect(request.reload.state).to eq('passed')
      end
    end

    # This behaviour doesn't feel quite right
    context 'when transitioning to "passed" with "failed" requests' do
      let(:target_state) { 'passed' }
      let(:request_state) { 'failed' }

      it 'updates the tube to "passed" with "failed" requests', :aggregate_failures do
        expect(transfer_request.reload.state).to eq('passed')
        expect(request.reload.state).to eq('failed')
      end
    end
  end

  context 'when the tube is: "processed_2"' do
    let(:transfer_request_state) { 'processed_2' }

    context 'when transitioning to "passed" with "started" requests' do
      let(:target_state) { 'passed' }
      let(:request_state) { 'started' }

      it 'updates the tube to "passed" with "passed" requests', :aggregate_failures do
        expect(transfer_request.reload.state).to eq('passed')
        expect(request.reload.state).to eq('passed')
      end
    end

    context 'when transitioning to "processed_3" with "started" requests' do
      let(:target_state) { 'processed_3' }
      let(:request_state) { 'started' }

      it 'updates the tube to "processed_3" with "started" requests', :aggregate_failures do
        expect(transfer_request.reload.state).to eq('processed_3')
        expect(request.reload.state).to eq('started')
      end
    end
  end

  context 'when the tube is: "processed_3"' do
    let(:transfer_request_state) { 'processed_3' }

    context 'when transitioning to "passed" with "passed" requests' do
      let(:target_state) { 'passed' }
      let(:request_state) { 'started' }

      it 'updates the tube to "passed" with "started" requests', :aggregate_failures do
        expect(transfer_request.reload.state).to eq('passed')
        expect(request.reload.state).to eq('passed')
      end
    end

    context 'when transitioning to "processed_4" with "started" requests' do
      let(:target_state) { 'processed_4' }
      let(:request_state) { 'started' }

      it 'updates the tube to "processed_4" with "started" requests', :aggregate_failures do
        expect(transfer_request.reload.state).to eq('processed_4')
        expect(request.reload.state).to eq('started')
      end
    end
  end

  context 'when the tube is: "processed_4"' do
    let(:transfer_request_state) { 'processed_4' }

    context 'when transitioning to "passed" with "passed" requests' do
      let(:target_state) { 'passed' }
      let(:request_state) { 'started' }

      it 'updates the tube to "passed" with "started" requests', :aggregate_failures do
        expect(transfer_request.reload.state).to eq('passed')
        expect(request.reload.state).to eq('passed')
      end
    end
  end

  context 'when the tube is: "passed"' do
    let(:transfer_request_state) { 'passed' }

    context 'when transitioning to "failed" with "started" requests' do
      let(:target_state) { 'failed' }
      let(:request_state) { 'started' }

      it 'updates the tube to "failed" with "failed" requests', :aggregate_failures do
        expect(transfer_request.reload.state).to eq('failed')
        expect(request.reload.state).to eq('failed')
      end
    end

    context 'when transitioning to "failed" with "passed" requests' do
      let(:target_state) { 'failed' }
      let(:request_state) { 'passed' }

      it 'updates the tube to "failed" with "passed" requests', :aggregate_failures do
        expect(transfer_request.reload.state).to eq('failed')
        expect(request.reload.state).to eq('passed')
      end
    end

    context 'when transitioning to "qc_complete" with "started" requests' do
      let(:target_state) { 'qc_complete' }
      let(:request_state) { 'started' }

      it 'updates the tube to "qc_complete" with "started" requests', :aggregate_failures do
        expect(transfer_request.reload.state).to eq('qc_complete')
        expect(request.reload.state).to eq('started')
      end
    end

    context 'when transitioning to "qc_complete" with "passed" requests' do
      let(:target_state) { 'qc_complete' }
      let(:request_state) { 'passed' }

      it 'updates the tube to "qc_complete" with "passed" requests', :aggregate_failures do
        expect(transfer_request.reload.state).to eq('qc_complete')
        expect(request.reload.state).to eq('passed')
      end
    end
  end

  context 'when the tube is: "qc_complete"' do
    let(:transfer_request_state) { 'qc_complete' }

    context 'when transitioning to "cancelled" with "started" requests' do
      let(:target_state) { 'cancelled' }
      let(:request_state) { 'started' }

      it 'updates the tube to "cancelled" with "started" requests', :aggregate_failures do
        expect(transfer_request.reload.state).to eq('cancelled')
        expect(request.reload.state).to eq('started')
      end
    end
  end

  describe 'events' do
    let(:transfer_request_state) { 'started' }

    context 'when the target state is passed, and the requests are in opened state' do
      let(:target_state) { 'passed' }
      let(:request_state) { 'started' }

      it 'fires an event' do
        expect(BroadcastEvent::PoolReleased.count).to eq(1)
        expect(BroadcastEvent::PoolReleased.last).to have_attributes(
          seed_type: Labware.name,
          seed: labware,
          user_id: user.id
        )
        expect(BroadcastEvent::PoolReleased.last.properties).to eq({ order_id: order.id })
      end

      context 'when there are multiple orders' do
        let(:request2) { create :request, target_asset: labware.receptacle, state: request_state, order: order2 }
        let(:requests) { [request, request2] }
        let(:order2) { create :order }

        it 'fires an event per order' do
          expect(BroadcastEvent::PoolReleased.count).to eq(2)
          expect(BroadcastEvent::PoolReleased.all).to all(
            have_attributes(seed_type: Labware.name, seed: labware, user_id: user.id)
          )
          order_ids = Set.new(BroadcastEvent::PoolReleased.all.map { |ev| ev.properties[:order_id] })
          expect(order_ids).to eq(Set[order.id, order2.id])
        end
      end
    end

    context 'when the target state is passed, and the requests are not in opened state' do
      let(:target_state) { 'passed' }
      let(:request_state) { 'failed' }

      it 'does not fire an event' do
        expect(BroadcastEvent::PoolReleased.count).to eq(0)
      end
    end

    context 'when the target state is not passed, and the requests are in opened state' do
      let(:target_state) { 'failed' }
      let(:request_state) { 'started' }

      it 'does not fire an event' do
        expect(BroadcastEvent::PoolReleased.count).to eq(0)
      end
    end

    context 'when the target state is not passed, and the requests are not in opened state' do
      let(:target_state) { 'failed' }
      let(:request_state) { 'failed' }

      it 'does not fire an event' do
        expect(BroadcastEvent::PoolReleased.count).to eq(0)
      end
    end
  end
end
