# frozen_string_literal: true

# require 'rails_helper'
require 'spec_helper'

RSpec.describe StateChanger::TubeRack do
  let(:user) { build_stubbed(:user) }
  let(:customer_accepts_responsibility) { false }
  let(:state_changer) { described_class.new(labware:, target_state:, user:, customer_accepts_responsibility:) }

  context 'when the target state is "passed"' do
    let(:target_state) { 'passed' }
    let(:request_state) { 'started' }
    let(:transfer_request_state) { 'started' }

    context 'when given a rack with a single tube' do
      let(:labware) { create(:tube_rack_with_tubes, locations: ['A1']) }
      let!(:request) { create(:request, target_asset: labware.tube_receptacles.first, state: request_state) }
      let!(:transfer_request) do
        create(:transfer_request, target_asset: labware.tube_receptacles.first, state: transfer_request_state)
      end

      before do
        labware.tube_receptacles.each { |tube_receptacle| tube_receptacle.aliquots << build(:aliquot, request:) }
        state_changer.update_labware_state
      end

      it 'when given receptacles with "started" requests', :aggregate_failures do
        expect(transfer_request.reload.state).to eq(target_state)
      end

      it 'updates the tube rack to "passed" state', :aggregate_failures do
        expect(labware.reload.state).to eq(target_state)
      end
    end

    context 'when given a rack with multiple tubes' do
      let(:labware) { create(:tube_rack_with_tubes, locations: %w[A1 A2 A3]) }
      let!(:requests) do
        [
          create(:request, target_asset: labware.tube_receptacles.first, state: request_state),
          create(:request, target_asset: labware.tube_receptacles[1], state: 'failed'),
          create(:request, target_asset: labware.tube_receptacles.last, state: request_state)
        ]
      end
      let!(:transfer_requests) do
        [
          create(:transfer_request, target_asset: labware.tube_receptacles.first, state: 'started'),
          create(:transfer_request, target_asset: labware.tube_receptacles[1], state: 'failed'),
          create(:transfer_request, target_asset: labware.tube_receptacles.last, state: 'started')
        ]
      end

      before do
        labware.tube_receptacles.each_with_index do |tube_receptacle, index|
          tube_receptacle.aliquots << build(:aliquot, request: requests[index])
        end
        state_changer.update_labware_state
      end

      it 'updates the tube to "passed" for receptacles with "started" requests', :aggregate_failures do
        expect(transfer_requests[0].reload.state).to eq(target_state)
        expect(transfer_requests[1].reload.state).to eq('failed')
        expect(transfer_requests[2].reload.state).to eq(target_state)
      end

      it 'updates the tube rack to "passed" state', :aggregate_failures do
        expect(labware.reload.state).to eq(target_state)
      end
    end

    context 'when given a rack with multiple tubes with a tube with a "pending" state' do
      let(:labware) { create(:tube_rack_with_tubes, locations: %w[A1 A2 A3]) }
      let!(:requests) do
        [
          create(:request, target_asset: labware.tube_receptacles.first, state: request_state),
          create(:request, target_asset: labware.tube_receptacles[1], state: 'pending'),
          create(:request, target_asset: labware.tube_receptacles.last, state: request_state)
        ]
      end
      let!(:transfer_requests) do
        [
          create(:transfer_request, target_asset: labware.tube_receptacles.first, state: 'started'),
          create(:transfer_request, target_asset: labware.tube_receptacles[1], state: 'pending'),
          create(:transfer_request, target_asset: labware.tube_receptacles.last, state: 'started')
        ]
      end

      before do
        labware.tube_receptacles.each_with_index do |tube_receptacle, index|
          tube_receptacle.aliquots << build(:aliquot, request: requests[index])
        end
        state_changer.update_labware_state
      end

      it 'updates the tube to "passed" for receptacles with "started" requests', :aggregate_failures do
        expect(transfer_requests[0].reload.state).to eq(target_state)
        expect(transfer_requests[2].reload.state).to eq(target_state)
      end

      it 'does not update the tube with the "pending" state', :aggregate_failures do
        expect(transfer_requests[1].reload.state).to eq('pending')
      end

      it 'updates the tube rack to "mixed" state', :aggregate_failures do
        expect(labware.reload.state).to eq('mixed')
      end
    end

    context 'when given a rack with multiple tubes with all tubes being in "failed" state' do
      let!(:labware) { create(:tube_rack_with_tubes, locations: %w[A1 A2 A3]) }
      let!(:requests) do
        [
          create(:request, target_asset: labware.tube_receptacles.first, state: 'failed'),
          create(:request, target_asset: labware.tube_receptacles[1], state: 'failed'),
          create(:request, target_asset: labware.tube_receptacles.last, state: 'failed')
        ]
      end
      let!(:transfer_requests) do
        [
          create(:transfer_request, target_asset: labware.tube_receptacles.first, state: 'failed'),
          create(:transfer_request, target_asset: labware.tube_receptacles[1], state: 'failed'),
          create(:transfer_request, target_asset: labware.tube_receptacles.last, state: 'failed')
        ]
      end

      before do
        labware.tube_receptacles.each_with_index do |tube_receptacle, index|
          tube_receptacle.aliquots << build(:aliquot, request: requests[index])
        end
        state_changer.update_labware_state
      end

      it 'updates transfer requests for receptacles with "failed" requests', :aggregate_failures do
        expect(transfer_requests[0].reload.state).to eq('failed')
        expect(transfer_requests[1].reload.state).to eq('failed')
        expect(transfer_requests[2].reload.state).to eq('failed')
      end

      it 'updates the tube rack to "failed" state', :aggregate_failures do
        expect(labware.reload.state).to eq('failed')
      end
    end
  end
end
