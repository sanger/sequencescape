# frozen_string_literal: true

# require 'rails_helper'
require 'spec_helper'

RSpec.describe StateChanger::TubeRack do
  let(:user) { build_stubbed(:user) }
  let(:customer_accepts_responsibility) { false }
  let(:labware) { create(:tube_rack_with_tubes, locations: ['A1']) }
  let(:state_changer) { described_class.new(labware:, target_state:, user:, customer_accepts_responsibility:) }

  let!(:transfer_request) do
    create(:transfer_request, target_asset: labware.tube_receptacles.first, state: transfer_request_state)
  end
  let!(:request) { create(:request, target_asset: labware.tube_receptacles.first, state: request_state) }

  context 'when the target state is "passed"' do
    let(:target_state) { 'passed' }
    let(:request_state) { 'started' }
    let(:transfer_request_state) { 'started' }

    context 'when transitioning to "passed" state for a rack with a single tube' do
      before do
        labware.tube_receptacles.each { |tube_receptacle| tube_receptacle.aliquots << build(:aliquot, request:) }
        state_changer.update_labware_state
      end

      it 'updates the tube to "passed" for receptacles with "started" requests', :aggregate_failures do
        expect(transfer_request.reload.state).to eq(target_state)
      end
    end

    context 'when transitioning to "passed" state for a rack with multiple tubes' do
      let(:labware) { create(:tube_rack_with_tubes, locations: %w[A1 A2 A3]) }
      let!(:requests) do
        [
          create(:request, target_asset: labware.tube_receptacles.first, state: request_state),
          create(:request, target_asset: labware.tube_receptacles[1], state: request_state),
          create(:request, target_asset: labware.tube_receptacles.last, state: request_state)
        ]
      end
      let!(:transfer_requests) do
        [
          create(:transfer_request, target_asset: labware.tube_receptacles.first, state: transfer_request_state),
          create(:transfer_request, target_asset: labware.tube_receptacles[1], state: transfer_request_state),
          create(:transfer_request, target_asset: labware.tube_receptacles.last, state: transfer_request_state)
        ]
      end

      before do
        labware.tube_receptacles.each_with_index do |tube_receptacle, index|
          tube_receptacle.aliquots << build(:aliquot, request: requests[index])
        end
        state_changer.update_labware_state
      end

      it 'updates the tube to "passed" for receptacles with "started" requests', :aggregate_failures do
        transfer_requests.each { |transfer_request| expect(transfer_request.reload.state).to eq(target_state) }
      end
    end
  end
end
