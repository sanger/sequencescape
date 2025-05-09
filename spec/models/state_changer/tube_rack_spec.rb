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

  before do
    labware.tube_receptacles.each { |tube_receptacle| tube_receptacle.aliquots << build(:aliquot, request:) }
    state_changer.update_labware_state
  end

  context 'when the target state is "pending"' do
    let(:target_state) { 'passed' }
    let(:request_state) { 'started' }
    let(:transfer_request_state) { 'started' }

    context 'when transitioning to "passed" state' do
      it 'updates the tube to "passed" with "failed" requests', :aggregate_failures do
        expect(transfer_request.reload.state).to eq('passed')
      end
    end
  end
end
