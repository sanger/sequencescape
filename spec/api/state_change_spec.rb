# frozen_string_literal: true

require 'rails_helper'
require 'shared_contexts/limber_shared_context'

describe '/api/1/state_changes' do
  subject(:url) { '/api/1/state_changes' }

  include_context 'a limber target plate with submissions'

  let(:authorised_app) { create :api_application }
  let(:parent_purpose) { create :plate_purpose }
  let(:user) { create :user }

  shared_examples 'a state_change_endpoint' do
    let(:response_code) { 201 }

    let(:payload) do
      {
        state_change: {
          user: user.uuid,
          target: target_plate.uuid,
          target_state: target_state,
          contents: contents,
          customer_accepts_responsibility: customer_accepts_responsibility,
          reason: reason
        }
      }.to_json
    end

    let(:response_body) do
      {
        state_change: {
          actions: {
            read: "http://www.example.com/api/1/#{StateChange.last.uuid}"
          },
          target: {
            actions: {
              read: "http://www.example.com/api/1/#{target_plate.uuid}"
            }
          },
          target_state: target_state,
          previous_state: previous_state,
          contents: contents,
          reason: reason
        }
      }.to_json
    end

    before { api_request :post, subject, payload }

    it 'supports resource creation', :aggregate_failures do
      expect(JSON.parse(response.body)).to include_json(JSON.parse(response_body))
      expect(status).to eq(response_code)
    end

    # This probably best belongs on a unit test. Just porting current feature tests for now.
    it 'transitions the selected well only', :aggregate_failures do
      all_wells = target_plate.maps.pluck(:description)
      affected_wells = contents || all_wells
      unaffected_wells = all_wells - affected_wells

      # We check the state of the wells, rather than the transfer requests, as we don't particularly care
      # about implementation here
      expect(target_plate.wells.located_at(affected_wells).map(&:state)).to all eq target_state
      expect(target_plate.wells.located_at(unaffected_wells).map(&:state)).to all eq previous_state
    end
  end

  shared_examples 'a failed state_change_endpoint' do
    let(:payload) do
      {
        state_change: {
          user: user.uuid,
          target: target_plate.uuid,
          target_state: target_state,
          reason: reason
        }
      }.to_json
    end

    before { api_request :post, subject, payload }

    it 'errors on resource creation', :aggregate_failures do
      expect(JSON.parse(response.body)).to include_json(JSON.parse(response_body))
      expect(status).to eq(response_code)
    end
  end

  describe '#post' do
    context 'when target_state is pending' do
      let(:target_state) { 'pending' }
      let(:reason) { nil }
      let(:previous_state) { 'pending' }
      let(:contents) { nil }
      let(:customer_accepts_responsibility) { nil }

      it_behaves_like 'a state_change_endpoint'
    end

    context 'when target_state is started' do
      let(:target_state) { 'started' }
      let(:reason) { nil }
      let(:previous_state) { 'pending' }
      let(:contents) { nil }
      let(:customer_accepts_responsibility) { nil }

      it_behaves_like 'a state_change_endpoint'
    end

    context 'when target_state is passed' do
      let(:target_state) { 'passed' }
      let(:reason) { nil }
      let(:previous_state) { 'pending' }
      let(:contents) { nil }
      let(:customer_accepts_responsibility) { nil }

      it_behaves_like 'a state_change_endpoint'
    end

    context 'when target_state is failed' do
      let(:target_state) { 'failed' }
      let(:reason) { 'because' }
      let(:previous_state) { 'pending' }
      let(:contents) { nil }
      let(:customer_accepts_responsibility) { nil }

      it_behaves_like 'a state_change_endpoint'
    end

    context 'when target_state is cancelled' do
      let(:target_state) { 'cancelled' }
      let(:reason) { 'because' }
      let(:previous_state) { 'pending' }
      let(:contents) { nil }
      let(:customer_accepts_responsibility) { nil }

      it_behaves_like 'a state_change_endpoint'
    end

    context 'when target_state is failed and a reason is missing' do
      let(:target_state) { 'failed' }
      let(:reason) { nil }
      let(:previous_state) { 'pending' }
      let(:contents) { nil }
      let(:customer_accepts_responsibility) { nil }
      let(:response_code) { 422 }

      let(:response_body) { { content: { reason: ["can't be blank"] } }.to_json }

      it_behaves_like 'a failed state_change_endpoint'
    end

    context 'when only one well is selected' do
      let(:target_state) { 'failed' }
      let(:reason) { 'because' }
      let(:previous_state) { 'pending' }
      let(:contents) { ['A1'] }
      let(:customer_accepts_responsibility) { nil }

      it_behaves_like 'a state_change_endpoint'
    end

    context 'when customer accepts responsibility' do
      let(:target_state) { 'failed' }
      let(:reason) { 'because' }
      let(:previous_state) { 'pending' }
      let(:contents) { ['A1'] }
      let(:customer_accepts_responsibility) { true }

      it_behaves_like 'a state_change_endpoint'
    end

    # If we end up on a legacy plate without request id on aliquot, we blow up
    # noisily to ensure we're aware there is a problem.
    context 'when on a legacy plate or one without obvious libraries' do
      let(:target_state) { 'failed' }
      let(:reason) { 'because' }
      let(:previous_state) { 'pending' }
      let(:contents) { nil }
      let(:customer_accepts_responsibility) { nil }

      let(:response_code) { 501 }

      let(:response_body) { { general: ['Could not find requests for wells.'] }.to_json }

      # Strip out our request ids to mimic legacy data
      before { target_plate.aliquots.update_all(request_id: nil) } # rubocop:disable Rails/SkipsModelValidations

      it_behaves_like 'a failed state_change_endpoint'
    end
  end
end
