# frozen_string_literal: true

require 'rails_helper'
require './spec/requests/api/v2/shared_examples/api_key_authenticatable'

describe 'State Changes API', with: :api_v2 do
  let(:base_endpoint) { '/api/v2/state_changes' }

  it_behaves_like 'ApiKeyAuthenticatable'

  context 'with a list of StateChanges' do
    let!(:state_changes) { create_list(:state_change, 5) }

    describe '#GET all StateChanges' do
      before { api_get base_endpoint }

      it 'responds with a success http code' do
        expect(response).to have_http_status(:success)
      end

      it 'returns the full list of StateChanges' do
        expect(json['data'].length).to eq(5)
      end
    end

    describe '#GET StateChange by ID' do
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

  describe '#PATCH a StateChange' do
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

  describe '#POST a new StateChange' do
    let(:user) { create(:user) }
    let(:plate) { create(:plate) }

    let(:base_attributes) do
      {
        'contents' => %w[A1 D2],
        'customer_accepts_responsibility' => true,
        'reason' => 'The plate is now passed.',
        'target_state' => 'passed'
      }
    end

    let(:user_relationship) { { 'data' => { 'id' => user.id, 'type' => 'users' } } }
    let(:target_relationship) { { 'data' => { 'id' => plate.id, 'type' => 'labware' } } }

    context 'with a valid payload' do
      shared_examples 'a valid request' do
        before { api_post base_endpoint, payload }

        it 'creates a new resource' do
          expect { api_post base_endpoint, payload }.to change(StateChange, :count).by(1)
        end

        it 'responds with success' do
          expect(response).to have_http_status(:success)
        end

        it 'responds with the correct attributes' do
          expect(json.dig('data', 'type')).to eq('state_changes')
          expect(json.dig('data', 'attributes', 'contents')).to eq(payload.dig('data', 'attributes', 'contents'))
          expect(json.dig('data', 'attributes', 'reason')).to eq(payload.dig('data', 'attributes', 'reason'))
          expect(json.dig('data', 'attributes', 'target_state')).to eq(
            payload.dig('data', 'attributes', 'target_state')
          )
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

        it 'applies the attributes to the new record' do
          new_record = StateChange.last

          expect(new_record.contents).to eq(payload.dig('data', 'attributes', 'contents'))
          expect(new_record.reason).to eq(payload.dig('data', 'attributes', 'reason'))
          expect(new_record.target_state).to eq(payload.dig('data', 'attributes', 'target_state'))
        end

        it 'applies the relationships to the new record' do
          new_record = StateChange.last

          expect(new_record.user).to eq(user)
          expect(new_record.target).to eq(plate)
        end
      end

      context 'with complete attributes' do
        let(:payload) do
          {
            'data' => {
              'type' => 'state_changes',
              'attributes' => base_attributes.merge({ 'user_uuid' => user.uuid, 'target_uuid' => plate.uuid })
            }
          }
        end

        it_behaves_like 'a valid request'
      end

      context 'with relationships' do
        let(:payload) do
          {
            'data' => {
              'type' => 'state_changes',
              'attributes' => base_attributes,
              'relationships' => {
                'user' => user_relationship,
                'target' => target_relationship
              }
            }
          }
        end

        it_behaves_like 'a valid request'
      end

      context 'with conflicting relationships' do
        let(:other_user) { create(:user) }
        let(:other_plate) { create(:plate) }
        let(:payload) do
          {
            'data' => {
              'type' => 'state_changes',
              'attributes' =>
                base_attributes.merge({ 'user_uuid' => other_user.uuid, 'target_uuid' => other_plate.uuid }),
              'relationships' => {
                'user' => user_relationship,
                'target' => target_relationship
              }
            }
          }
        end

        # This test should pass because the relationships are preferred over the attributes.
        it_behaves_like 'a valid request'
      end
    end

    context 'with a read-only attribute in the payload' do
      shared_examples 'a request with a disallowed attribute' do
        before { api_post base_endpoint, payload }

        it 'does not create a new resource' do
          expect { api_post base_endpoint, payload }.not_to change(StateChange, :count)
        end

        it 'responds with bad_request' do
          expect(response).to have_http_status(:bad_request)
        end

        it 'specifies which attribute was not allowed ' do
          expect(json.dig('errors', 0, 'detail')).to eq("#{disallowed_attribute} is not allowed.")
        end
      end

      context 'with previous_state' do
        let(:disallowed_attribute) { 'previous_state' }
        let(:payload) do
          {
            'data' => {
              'type' => 'state_changes',
              'attributes' => base_attributes.merge({ 'previous_state' => 'waiting' })
            }
          }
        end

        it_behaves_like 'a request with a disallowed attribute'
      end

      context 'with uuid' do
        let(:disallowed_attribute) { 'uuid' }
        let(:payload) do
          {
            'data' => {
              'type' => 'state_changes',
              'attributes' => base_attributes.merge({ 'uuid' => '111111-2222-3333-4444-555555666666' })
            }
          }
        end

        it_behaves_like 'a request with a disallowed attribute'
      end
    end

    context 'without a required attribute' do
      context 'without target_state' do
        let(:payload) do
          {
            'data' => {
              'type' => 'state_changes',
              'attributes' =>
                base_attributes.merge({ 'target_state' => nil, 'user_uuid' => user.uuid, 'target_uuid' => plate.uuid })
            }
          }
        end

        before { api_post base_endpoint, payload }

        it 'does not create a new resource' do
          expect { api_post base_endpoint, payload }.not_to change(StateChange, :count)
        end

        it 'responds with unprocessable_entity' do
          expect(response).to have_http_status(:unprocessable_entity)
        end

        it 'specifies which attribute was not allowed ' do
          expect(json.dig('errors', 0, 'detail')).to eq("target_state - can't be blank")
        end
      end
    end

    context 'without a required relationship' do
      shared_examples 'a request without required relationships' do
        before { api_post base_endpoint, payload }

        it 'does not create a new resource' do
          expect { api_post base_endpoint, payload }.not_to change(StateChange, :count)
        end

        it 'responds with unprocessable_entity' do
          expect(response).to have_http_status(:unprocessable_entity)
        end

        it 'specifies which attribute was not allowed ' do
          expect(json.dig('errors', 0, 'detail')).to eq("#{missing_relationship} - must exist")
        end
      end

      context 'without user_uuid' do
        let(:missing_relationship) { 'user' }
        let(:payload) do
          {
            'data' => {
              'type' => 'state_changes',
              'attributes' => base_attributes.merge({ 'target_uuid' => plate.uuid })
            }
          }
        end

        it_behaves_like 'a request without required relationships'
      end

      context 'without target_uuid' do
        let(:missing_relationship) { 'target' }
        let(:payload) do
          {
            'data' => {
              'type' => 'state_changes',
              'attributes' => base_attributes.merge({ 'user_uuid' => user.uuid })
            }
          }
        end

        it_behaves_like 'a request without required relationships'
      end

      context 'without user' do
        let(:missing_relationship) { 'user' }
        let(:payload) do
          {
            'data' => {
              'type' => 'state_changes',
              'attributes' => base_attributes,
              'relationships' => {
                'target' => target_relationship
              }
            }
          }
        end

        it_behaves_like 'a request without required relationships'
      end

      context 'without target' do
        let(:missing_relationship) { 'target' }
        let(:payload) do
          {
            'data' => {
              'type' => 'state_changes',
              'attributes' => base_attributes,
              'relationships' => {
                'user' => user_relationship
              }
            }
          }
        end

        it_behaves_like 'a request without required relationships'
      end
    end
  end
end
