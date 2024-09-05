# frozen_string_literal: true

require 'rails_helper'
require './spec/requests/api/v2/shared_examples/api_key_authenticatable'
require './spec/requests/api/v2/shared_examples/post_requests'

describe 'Bait Library Layouts API', with: :api_v2 do
  let(:model_class) { BaitLibraryLayout }

  let(:base_endpoint) { "/api/v2/#{resource_type}" }
  let(:resource_type) { model_class.name.demodulize.pluralize.underscore }

  it_behaves_like 'ApiKeyAuthenticatable'

  context 'with a list of resources' do
    let(:resource_count) { 5 }

    before { create_list(:bait_library_layout, resource_count) }

    describe '#GET all the resources' do
      before { api_get base_endpoint }

      it 'responds with a success http code' do
        expect(response).to have_http_status(:success)
      end

      it 'returns data for all the resources' do
        expect(json['data'].length).to eq(resource_count)
      end
    end
  end

  context 'with a single resource' do
    describe '#GET the resource by ID' do
      let(:resource) { create :bait_library_layout }

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
          expect(json.dig('data', 'attributes', 'layout')).to eq(resource.layout)
          expect(json.dig('data', 'attributes', 'uuid')).to eq(resource.uuid)
        end

        it 'excludes unfetchable attributes' do
          expect(json.dig('data', 'attributes', 'plate_uuid')).not_to be_present
          expect(json.dig('data', 'attributes', 'user_uuid')).not_to be_present
        end

        it 'returns references to related resources' do
          expect(json.dig('data', 'relationships', 'plate')).to be_present
          expect(json.dig('data', 'relationships', 'user')).to be_present
        end

        it 'does not include attributes for related resources' do
          expect(json['included']).not_to be_present
        end
      end

      context 'with included relationships' do
        context 'with plate' do
          let(:related_name) { 'plate' }
          let(:related_type) { 'plates' }

          it_behaves_like 'a POST request including a has_one relationship'
        end

        context 'with user' do
          let(:related_name) { 'user' }
          let(:related_type) { 'users' }

          it_behaves_like 'a POST request including a has_one relationship'
        end
      end
    end
  end

  describe '#PATCH a resource' do
    let(:resource) { create :bait_library_layout }
    let(:payload) do
      {
        'data' => {
          'id' => resource.id,
          'type' => resource_type,
          'attributes' => {
            'user_uuid' => '11111111-2222-3333-4444-555555666666',
          }
        }
      }
    end

    it 'finds no route for the method' do
      expect { api_patch "#{base_endpoint}/#{resource.id}", payload }.to raise_error(
        ActionController::RoutingError
      )
    end
  end

  describe '#POST a new resource' do
    let(:user) { create(:user) }
    let(:plate) { create(:plate) }

    let(:base_attributes) { {} } # There are no attributes to set besides ones for relationships being tested.

    let(:user_relationship) { { 'data' => { 'id' => user.id, 'type' => 'users' } } }
    let(:plate_relationship) { { 'data' => { 'id' => plate.id, 'type' => 'plates' } } }

    context 'with a valid payload' do
      shared_examples 'a valid POST request' do
        def perform_post
          api_post base_endpoint, payload
        end

        it 'creates a new resource' do
          expect { perform_post }.to change(model_class, :count).by(1)
        end

        it 'responds with success' do
          perform_post

          expect(response).to have_http_status(:success)
        end

        it 'responds with the correct attributes' do
          perform_post
          new_record = model_class.last

          expect(json.dig('data', 'type')).to eq(resource_type)
          expect(json.dig('data', 'attributes', 'layout')).to eq(new_record.layout)
        end

        it 'excludes unfetchable attributes' do
          perform_post

          expect(json.dig('data', 'attributes', 'plate_uuid')).not_to be_present
          expect(json.dig('data', 'attributes', 'user_uuid')).not_to be_present
        end

        it 'returns references to related resources' do
          perform_post

          expect(json.dig('data', 'relationships', 'plate')).to be_present
          expect(json.dig('data', 'relationships', 'user')).to be_present
        end

        it 'applies the relationships to the new record' do
          perform_post
          new_record = model_class.last

          expect(new_record.plate).to eq(plate)
          expect(new_record.user).to eq(user)
        end
      end

      context 'with complete attributes' do
        let(:payload) do
          {
            'data' => {
              'type' => resource_type,
              'attributes' => base_attributes.merge({ 'user_uuid' => user.uuid, 'plate_uuid' => plate.uuid })
            }
          }
        end

        it_behaves_like 'a valid POST request'
      end

      context 'with relationships' do
        let(:payload) do
          {
            'data' => {
              'type' => resource_type,
              'attributes' => base_attributes,
              'relationships' => {
                'user' => user_relationship,
                'plate' => plate_relationship
              }
            }
          }
        end

        it_behaves_like 'a valid POST request'
      end

      context 'with conflicting relationships' do
        let(:other_user) { create(:user) }
        let(:other_plate) { create(:plate) }
        let(:payload) do
          {
            'data' => {
              'type' => resource_type,
              'attributes' =>
                base_attributes.merge({ 'user_uuid' => other_user.uuid, 'plate_uuid' => other_plate.uuid }),
              'relationships' => {
                'user' => user_relationship,
                'plate' => plate_relationship
              }
            }
          }
        end

        # This test should pass because the relationships are preferred over the attributes.
        it_behaves_like 'a valid POST request'
      end
    end

    context 'with a read-only attribute in the payload' do
      context 'with uuid' do
        let(:disallowed_attribute) { 'uuid' }
        let(:payload) do
          {
            'data' => {
              'type' => resource_type,
              'attributes' => base_attributes.merge({ 'uuid' => '111111-2222-3333-4444-555555666666' })
            }
          }
        end

        it_behaves_like 'a POST request with a disallowed attribute'
      end
    end

    context 'without a required relationship' do
      context 'without user_uuid' do
        let(:error_detail_message) { "user - can't be blank" }
        let(:payload) do
          {
            'data' => {
              'type' => resource_type,
              'attributes' => base_attributes.merge({ 'plate_uuid' => plate.uuid })
            }
          }
        end

        it_behaves_like 'a POST request without a required relationship'
      end

      context 'without plate_uuid' do
        let(:error_detail_message) { "plate - can't be blank" }
        let(:payload) do
          {
            'data' => {
              'type' => resource_type,
              'attributes' => base_attributes.merge({ 'user_uuid' => user.uuid })
            }
          }
        end

        it_behaves_like 'a POST request without a required relationship'
      end

      context 'without user' do
        let(:error_detail_message) { "user - can't be blank" }
        let(:payload) do
          {
            'data' => {
              'type' => resource_type,
              'attributes' => base_attributes,
              'relationships' => {
                'plate' => plate_relationship
              }
            }
          }
        end

        it_behaves_like 'a POST request without a required relationship'
      end

      context 'without plate' do
        let(:error_detail_message) { "plate - can't be blank" }
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

        it_behaves_like 'a POST request without a required relationship'
      end
    end
  end
end
