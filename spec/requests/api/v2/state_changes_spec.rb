# frozen_string_literal: true

require 'rails_helper'
require './spec/requests/api/v2/shared_examples/api_key_authenticatable'

describe 'State Changes API', with: :api_v2 do
  let(:base_endpoint) { '/api/v2/state_changes' }

  it_behaves_like 'ApiKeyAuthenticatable'

  context 'with a list of StateChanges' do
    let!(:state_changes) { create_list(:state_change, 5) }

    describe '#get all StateChanges' do
      before { api_get base_endpoint }

      it 'responds with a success http code' do
        expect(response).to have_http_status(:success)
      end

      it 'returns the full list of StateChanges' do
        expect(json['data'].length).to eq(5)
      end
    end

    describe '#get StateChange by ID' do
      let(:state_change) { state_changes.first }

      context 'without included relationships' do
        before { api_get "#{base_endpoint}/#{state_change.id}" }

        it 'responds with a success http code' do
          expect(response).to have_http_status(:success)
        end

        it 'returns the correct StateChange' do
          expect(json.dig('data', 'id')).to eq(state_change.id.to_s)
          expect(json.dig('data', 'type')).to eq('state_changes')
        end

        it 'returns the correct attributes' do
          expect(json.dig('data', 'attributes', 'contents')).to eq(state_change.contents)
          expect(json.dig('data', 'attributes', 'previous_state')).to eq(state_change.previous_state)
          expect(json.dig('data', 'attributes', 'reason')).to eq(state_change.reason)
          expect(json.dig('data', 'attributes', 'target_state')).to eq(state_change.target_state)
          expect(json.dig('data', 'attributes', 'uuid')).to eq(state_change.uuid)
        end

        it 'excludes unfetchable attributes' do
          expect(json.dig('data', 'attributes', 'customer_accepts_responsibility')).not_to be_present
          expect(json.dig('data', 'attributes', 'target_uuid')).not_to be_present
          expect(json.dig('data', 'attributes', 'user_uuid')).not_to be_present
        end

        it 'returns references to related resources' do
          expect(json.dig('data', 'relationships', 'user')).to be_present
          expect(json.dig('data', 'relationships', 'target')).to be_present
        end

        it 'does not include attributes for related resources' do
          expect(json['included']).not_to be_present
        end
      end

      context 'with included relationships' do
        before { api_get "#{base_endpoint}/#{state_change.id}?include=user,target" }

        it 'responds with a success http code' do
          expect(response).to have_http_status(:success)
        end

        it 'returns the correct user relationship' do
          user = json['included'].find { |i| i['type'] == 'users' }
          expect(user['id']).to eq(state_change.user.id.to_s)
          expect(user['type']).to eq('users')
        end

        it 'returns the correct target relationship' do
          target = json['included'].find { |i| i['type'] == 'labware' }
          expect(target['id']).to eq(state_change.target.id.to_s)
          expect(target['type']).to eq('labware')
        end
      end
    end
  end

  describe '#patch a StateChange' do
    let(:resource_model) { create(:state_change) }
    let(:payload) do
      {
        'data' => {
          'id' => resource_model.id,
          'type' => 'state_changes',
          'attributes' => {
            'target_state' => 'passed'
          }
        }
      }
    end

    it 'finds no route for the method' do
      expect { api_patch "#{base_endpoint}/#{resource_model.id}", payload }.to raise_error(
        ActionController::RoutingError
      )
    end
  end

  describe '#post a new StateChange' do
    let(:payload) { { 'data' => { 'type' => 'state_changes', 'attributes' => { 'target_state' => 'passed' } } } }

    it 'finds no routes for the method' do
      expect { api_post base_endpoint, payload }.to raise_error(ActionController::RoutingError)
    end
  end
end
