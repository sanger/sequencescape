# frozen_string_literal: true

# require 'rails_helper'
require 'spec_helper'

RSpec.describe StateChanger::StockTube do
  let(:state_changer) do
    described_class.new(
      labware:,
      target_state:,
      user:,
      customer_accepts_responsibility:
    )
  end

  let(:user) { build_stubbed :user }
  let(:customer_accepts_responsibility) { false }
  let(:labware) { create :tube }
  let!(:transfer_request) { create :transfer_request, target_asset: labware.receptacle, state: transfer_request_state }
  let!(:request) { create :request, target_asset: labware.receptacle, state: request_state }

  before do
    labware.receptacle.aliquots << build(:aliquot, request:)
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

    # This is questionable?
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

      it 'updates the tube to "failed" with "failed" requests', :aggregate_failures do
        expect(transfer_request.reload.state).to eq('failed')
        expect(request.reload.state).to eq('failed')
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

      it 'updates the tube to "passed" with "started" requests', :aggregate_failures do
        expect(transfer_request.reload.state).to eq('passed')
        expect(request.reload.state).to eq('started')
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

      it 'updates the tube to "failed" with "failed" requests', :aggregate_failures do
        expect(transfer_request.reload.state).to eq('failed')
        expect(request.reload.state).to eq('failed')
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

    context 'when transitioning to "passed" with "pending" requests' do
      let(:target_state) { 'passed' }
      let(:request_state) { 'pending' }

      it 'updates the tube to "passed" with "pending" requests', :aggregate_failures do
        expect(transfer_request.reload.state).to eq('failed')
        expect(request.reload.state).to eq('pending')
      end
    end

    context 'when transitioning to "passed" with "started" requests' do
      let(:target_state) { 'passed' }
      let(:request_state) { 'started' }

      it 'updates the tube to "passed" with "started" requests', :aggregate_failures do
        expect(transfer_request.reload.state).to eq('failed')
        expect(request.reload.state).to eq('started')
      end
    end

    context 'when transitioning to "passed" with "failed" requests' do
      let(:target_state) { 'passed' }
      let(:request_state) { 'failed' }

      it 'updates the tube to "passed" with "failed" requests', :aggregate_failures do
        expect(transfer_request.reload.state).to eq('failed')
        expect(request.reload.state).to eq('failed')
      end
    end
  end

  context 'when the tube is: "processed_2"' do
    let(:transfer_request_state) { 'processed_2' }

    context 'when transitioning to "passed" with "started" requests' do
      let(:target_state) { 'passed' }
      let(:request_state) { 'started' }

      it 'updates the tube to "passed" with "started" requests', :aggregate_failures do
        expect(transfer_request.reload.state).to eq('passed')
        expect(request.reload.state).to eq('started')
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

    context 'when transitioning to "passed" with "started" requests' do
      let(:target_state) { 'passed' }
      let(:request_state) { 'started' }

      it 'updates the tube to "passed" with "started" requests', :aggregate_failures do
        expect(transfer_request.reload.state).to eq('passed')
        expect(request.reload.state).to eq('started')
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

    context 'when transitioning to "passed" with "started" requests' do
      let(:target_state) { 'passed' }
      let(:request_state) { 'started' }

      it 'updates the tube to "passed" with "started" requests', :aggregate_failures do
        expect(transfer_request.reload.state).to eq('passed')
        expect(request.reload.state).to eq('started')
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

      it 'updates the tube to "failed" with "failed" requests', :aggregate_failures do
        expect(transfer_request.reload.state).to eq('failed')
        expect(request.reload.state).to eq('failed')
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
end
