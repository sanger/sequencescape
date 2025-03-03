# frozen_string_literal: true

require 'rails_helper'
require './spec/requests/api/v2/shared_examples/api_key_authenticatable'
require './spec/requests/api/v2/shared_examples/requests'

describe 'State Changes API', with: :api_v2 do
  let(:model_class) { StateChange }
  let(:base_endpoint) { "/api/v2/#{resource_type}" }
  let(:resource_type) { model_class.name.demodulize.pluralize.underscore }

  it_behaves_like 'ApiKeyAuthenticatable'

  context 'with a list of resource' do
    let(:resource_count) { 5 }

    before { create_list(:state_change, resource_count) }

    describe '#GET all resources' do
      before { api_get base_endpoint }

      it 'responds with a success http code' do
        expect(response).to have_http_status(:success)
      end

      it 'returns all the resources' do
        expect(json['data'].length).to eq(resource_count)
      end
    end
  end

  context 'with a single resource' do
    describe '#GET resource by ID' do
      let(:resource) { create(:state_change) }

      context 'without included relationships' do
        before { api_get "#{base_endpoint}/#{resource.id}" }

        it 'responds with a success http code' do
          expect(response).to have_http_status(:success)
        end

        it 'returns the correct resource' do
          expect(json.dig('data', 'id')).to eq(resource.id.to_s)
          expect(json.dig('data', 'type')).to eq(resource_type)
        end

        it 'returns the correct attributes' do
          expect(json.dig('data', 'attributes', 'contents')).to eq(resource.contents)
          expect(json.dig('data', 'attributes', 'previous_state')).to eq(resource.previous_state)
          expect(json.dig('data', 'attributes', 'reason')).to eq(resource.reason)
          expect(json.dig('data', 'attributes', 'target_state')).to eq(resource.target_state)
          expect(json.dig('data', 'attributes', 'uuid')).to eq(resource.uuid)
        end

        it 'excludes unfetchable attributes' do
          expect(json.dig('data', 'attributes', 'customer_accepts_responsibility')).not_to be_present
          expect(json.dig('data', 'attributes', 'target_uuid')).not_to be_present
          expect(json.dig('data', 'attributes', 'user_uuid')).not_to be_present
        end

        it 'returns references to related resources' do
          expect(json.dig('data', 'relationships', 'target')).to be_present
          expect(json.dig('data', 'relationships', 'user')).to be_present
        end

        it 'does not include attributes for related resources' do
          expect(json['included']).not_to be_present
        end
      end

      context 'with included relationships' do
        it_behaves_like 'a GET request including a has_one relationship', 'user'
        it_behaves_like 'a GET request including a has_one relationship', 'target'
      end
    end
  end

  describe '#PATCH a resource' do
    let(:resource_model) { create(:state_change) }
    let(:payload) do
      {
        'data' => {
          'id' => resource_model.id,
          'type' => resource_type,
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

  describe '#POST a create request' do
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
          expect { api_post base_endpoint, payload }.to change(model_class, :count).by(1)
        end

        it 'responds with success' do
          expect(response).to have_http_status(:success)
        end

        it 'responds with the correct attributes' do
          new_record = model_class.last

          expect(json.dig('data', 'type')).to eq(resource_type)
          expect(json.dig('data', 'attributes', 'contents')).to eq(new_record.contents)
          expect(json.dig('data', 'attributes', 'reason')).to eq(new_record.reason)
          expect(json.dig('data', 'attributes', 'target_state')).to eq(new_record.target_state)
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
          new_record = model_class.last

          expect(new_record.contents).to eq(payload.dig('data', 'attributes', 'contents'))
          expect(new_record.reason).to eq(payload.dig('data', 'attributes', 'reason'))
          expect(new_record.target_state).to eq(payload.dig('data', 'attributes', 'target_state'))
        end

        it 'applies the relationships to the new record' do
          new_record = model_class.last

          expect(new_record.user).to eq(user)
          expect(new_record.target).to eq(plate)
        end
      end

      context 'with complete attributes' do
        let(:payload) do
          {
            'data' => {
              'type' => resource_type,
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
              'type' => resource_type,
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
              'type' => resource_type,
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
      context 'with previous_state' do
        let(:disallowed_value) { 'previous_state' }
        let(:payload) do
          {
            'data' => {
              'type' => resource_type,
              'attributes' => base_attributes.merge({ 'previous_state' => 'waiting' })
            }
          }
        end

        it_behaves_like 'a POST request with a disallowed value'
      end

      context 'with uuid' do
        let(:disallowed_value) { 'uuid' }
        let(:payload) do
          {
            'data' => {
              'type' => resource_type,
              'attributes' => base_attributes.merge({ 'uuid' => '111111-2222-3333-4444-555555666666' })
            }
          }
        end

        it_behaves_like 'a POST request with a disallowed value'
      end
    end

    context 'without a required attribute' do
      context 'without target_state' do
        let(:error_detail_message) { "target_state - can't be blank" }
        let(:payload) do
          {
            'data' => {
              'type' => resource_type,
              'attributes' =>
                base_attributes.merge({ 'target_state' => nil, 'user_uuid' => user.uuid, 'target_uuid' => plate.uuid })
            }
          }
        end

        it_behaves_like 'an unprocessable POST request with a specific error'
      end
    end

    context 'without a required relationship' do
      context 'without user_uuid' do
        let(:error_detail_message) { 'user - must exist' }
        let(:payload) do
          {
            'data' => {
              'type' => resource_type,
              'attributes' => base_attributes.merge({ 'target_uuid' => plate.uuid })
            }
          }
        end

        it_behaves_like 'an unprocessable POST request with a specific error'
      end

      context 'without target_uuid' do
        let(:error_detail_message) { 'target - must exist' }
        let(:payload) do
          { 'data' => { 'type' => resource_type, 'attributes' => base_attributes.merge({ 'user_uuid' => user.uuid }) } }
        end

        it_behaves_like 'an unprocessable POST request with a specific error'
      end

      context 'without user' do
        let(:error_detail_message) { 'user - must exist' }
        let(:payload) do
          {
            'data' => {
              'type' => resource_type,
              'attributes' => base_attributes,
              'relationships' => {
                'target' => target_relationship
              }
            }
          }
        end

        it_behaves_like 'an unprocessable POST request with a specific error'
      end

      context 'without target' do
        let(:error_detail_message) { 'target - must exist' }
        let(:payload) do
          {
            'data' => {
              'type' => resource_type,
              'attributes' => base_attributes,
              'relationships' => {
                'user' => user_relationship
              }
            }
          }
        end

        it_behaves_like 'an unprocessable POST request with a specific error'
      end
    end
  end
end
