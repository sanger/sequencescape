# frozen_string_literal: true

require 'rails_helper'
require './spec/requests/api/v2/shared_examples/api_key_authenticatable'
require './spec/requests/api/v2/shared_examples/requests'

describe 'Plate Conversions API', with: :api_v2 do
  let(:model_class) { PlateConversion }
  let(:base_endpoint) { "/api/v2/#{resource_type}" }
  let(:resource_type) { model_class.name.demodulize.pluralize.underscore }

  it_behaves_like 'ApiKeyAuthenticatable'

  context 'with a list of resources' do
    let(:resource_count) { 5 }

    before { create_list(:plate_conversion, resource_count) }

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
      let(:resource) { create(:plate_conversion) }

      context 'without included relationships' do
        before { api_get "#{base_endpoint}/#{resource.id}" }

        it 'responds with a success http code' do
          expect(response).to have_http_status(:success)
        end

        it 'returns the resource with the correct id' do
          expect(json.dig('data', 'id')).to eq(resource.id.to_s)
        end

        it 'returns the resource with the correct type' do
          expect(json.dig('data', 'type')).to eq(resource_type)
        end

        it 'returns the correct attributes' do
          expect(json.dig('data', 'attributes', 'uuid')).to eq(resource.uuid)
        end

        it 'excludes the unfetchable parent_uuid' do
          expect(json.dig('data', 'attributes', 'parent_uuid')).not_to be_present
        end

        it 'excludes the unfetchable purpose_uuid' do
          expect(json.dig('data', 'attributes', 'purpose_uuid')).not_to be_present
        end

        it 'excludes the unfetchable target_uuid' do
          expect(json.dig('data', 'attributes', 'target_uuid')).not_to be_present
        end

        it 'excludes the unfetchable user_uuid' do
          expect(json.dig('data', 'attributes', 'user_uuid')).not_to be_present
        end

        it 'returns a reference to the parent relationship' do
          expect(json.dig('data', 'relationships', 'parent')).to be_present
        end

        it 'returns a reference to the purpose relationship' do
          expect(json.dig('data', 'relationships', 'purpose')).to be_present
        end

        it 'returns a reference to the target relationship' do
          expect(json.dig('data', 'relationships', 'target')).to be_present
        end

        it 'returns a reference to the user relationship' do
          expect(json.dig('data', 'relationships', 'user')).to be_present
        end

        it 'does not include attributes for related resources' do
          expect(json['included']).not_to be_present
        end
      end

      context 'with included relationships' do
        it_behaves_like 'a GET request including a has_one relationship', 'parent'
        it_behaves_like 'a GET request including a has_one relationship', 'purpose'
        it_behaves_like 'a GET request including a has_one relationship', 'target'
        it_behaves_like 'a GET request including a has_one relationship', 'user'
      end
    end
  end

  describe '#PATCH a resource' do
    let(:resource_model) { create(:plate_conversion) }
    let(:payload) { { data: { id: resource_model.id, type: resource_type, attributes: {} } } }

    it 'finds no route for the method' do
      expect { api_patch "#{base_endpoint}/#{resource_model.id}", payload }.to raise_error(
        ActionController::RoutingError
      )
    end
  end

  describe '#POST a create request' do
    let(:parent) { create(:plate) }
    let(:purpose) { create(:plate_purpose) }
    let(:target) { create(:plate) }
    let(:user) { create(:user) }

    let(:parent_relationship) { { data: { id: parent.id, type: 'plates' } } }
    let(:purpose_relationship) { { data: { id: purpose.id, type: 'plate_purposes' } } }
    let(:target_relationship) { { data: { id: target.id, type: 'plates' } } }
    let(:user_relationship) { { data: { id: user.id, type: 'users' } } }

    context 'with a valid payload' do
      shared_examples 'a valid request' do
        before { api_post base_endpoint, payload }

        it 'creates a new resource' do
          expect { api_post base_endpoint, payload }.to change(model_class, :count).by(1)
        end

        it 'responds with success' do
          expect(response).to have_http_status(:success)
        end

        it 'responds with a resource of the correct type' do
          expect(json.dig('data', 'type')).to eq(resource_type)
        end

        it 'responds with a uuid matching the new record' do
          new_record = model_class.last
          expect(json.dig('data', 'attributes', 'uuid')).to eq(new_record.uuid)
        end

        it 'excludes the unfetchable parent_uuid' do
          expect(json.dig('data', 'attributes', 'parent_uuid')).not_to be_present
        end

        it 'excludes the unfetchable purpose_uuid' do
          expect(json.dig('data', 'attributes', 'purpose_uuid')).not_to be_present
        end

        it 'excludes the unfetchable target_uuid' do
          expect(json.dig('data', 'attributes', 'target_uuid')).not_to be_present
        end

        it 'excludes the unfetchable user_uuid' do
          expect(json.dig('data', 'attributes', 'user_uuid')).not_to be_present
        end

        it 'returns a reference to the parent relationship' do
          expect(json.dig('data', 'relationships', 'parent')).to be_present
        end

        it 'returns a reference to the purpose relationship' do
          expect(json.dig('data', 'relationships', 'purpose')).to be_present
        end

        it 'returns a reference to the target relationship' do
          expect(json.dig('data', 'relationships', 'target')).to be_present
        end

        it 'returns a reference to the user relationship' do
          expect(json.dig('data', 'relationships', 'user')).to be_present
        end

        it 'associates the parent with the new record' do
          new_record = model_class.last
          expect(new_record.parent).to eq(parent)
        end

        it 'associates the purpose with the new record' do
          new_record = model_class.last
          expect(new_record.purpose).to eq(purpose)
        end

        it 'associates the target with the new record' do
          new_record = model_class.last
          expect(new_record.target).to eq(target)
        end

        it 'associates the user with the new record' do
          new_record = model_class.last
          expect(new_record.user).to eq(user)
        end

        it 'converts the target to the given purpose' do
          new_record = model_class.last
          expect(new_record.target.purpose).to eq(purpose)
        end

        it 'makes the parent plate the parent of the target plate' do
          new_record = model_class.last
          expect(new_record.target.parent).to eq(parent) unless parent.nil?
        end

        it 'makes the target plate a child of the parent plate' do
          new_record = model_class.last
          expect(new_record.parent.children).to include(target) unless parent.nil?
        end
      end

      context 'with complete attributes' do
        let(:payload) do
          {
            data: {
              type: resource_type,
              attributes: {
                parent_uuid: parent.uuid,
                purpose_uuid: purpose.uuid,
                target_uuid: target.uuid,
                user_uuid: user.uuid
              }
            }
          }
        end

        it_behaves_like 'a valid request'
      end

      context 'with mandatory attributes' do
        let(:parent) { nil }
        let(:payload) do
          {
            data: {
              type: resource_type,
              attributes: {
                purpose_uuid: purpose.uuid,
                target_uuid: target.uuid,
                user_uuid: user.uuid
              }
            }
          }
        end

        it_behaves_like 'a valid request'
      end

      context 'with complete relationships' do
        let(:payload) do
          {
            data: {
              type: resource_type,
              relationships: {
                parent: parent_relationship,
                purpose: purpose_relationship,
                target: target_relationship,
                user: user_relationship
              }
            }
          }
        end

        it_behaves_like 'a valid request'
      end

      context 'with mandatory relationships' do
        let(:parent) { nil }
        let(:payload) do
          {
            data: {
              type: resource_type,
              relationships: {
                purpose: purpose_relationship,
                target: target_relationship,
                user: user_relationship
              }
            }
          }
        end

        it_behaves_like 'a valid request'
      end

      context 'with conflicting relationships' do
        let(:other_parent) { create(:plate) }
        let(:other_purpose) { create(:plate_purpose) }
        let(:other_target) { create(:plate) }
        let(:other_user) { create(:user) }
        let(:payload) do
          {
            data: {
              type: resource_type,
              attributes: {
                parent_uuid: other_parent.uuid,
                purpose_uuid: other_purpose.uuid,
                target_uuid: other_target.uuid,
                user_uuid: other_user.uuid
              },
              relationships: {
                parent: parent_relationship,
                purpose: purpose_relationship,
                target: target_relationship,
                user: user_relationship
              }
            }
          }
        end

        # This test should pass because the relationships are preferred over the attributes.
        it_behaves_like 'a valid request'
      end
    end

    context 'with a read-only attribute in the payload' do
      context 'with uuid' do
        let(:disallowed_value) { 'uuid' }
        let(:payload) { { data: { type: resource_type, attributes: { uuid: '111111-2222-3333-4444-555555666666' } } } }

        it_behaves_like 'a POST request with a disallowed value'
      end
    end

    context 'without a required relationship' do
      context 'without purpose or purpose_uuid' do
        let(:error_detail_message) { "purpose - can't be blank" }
        let(:payload) do
          { data: { type: resource_type, relationships: { target: target_relationship, user: user_relationship } } }
        end

        it_behaves_like 'an unprocessable POST request with a specific error'
      end

      context 'without target or target_uuid' do
        let(:error_detail_message) { "target - can't be blank" }
        let(:payload) do
          { data: { type: resource_type, relationships: { purpose: purpose_relationship, user: user_relationship } } }
        end

        it_behaves_like 'an unprocessable POST request with a specific error'
      end

      context 'without a user or user_uuid' do
        let(:error_detail_message) { "user - can't be blank" }
        let(:payload) do
          {
            data: {
              type: resource_type,
              relationships: {
                purpose: purpose_relationship,
                target: target_relationship
              }
            }
          }
        end

        it_behaves_like 'an unprocessable POST request with a specific error'
      end
    end
  end
end
