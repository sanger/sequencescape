# frozen_string_literal: true

require 'rails_helper'
require './spec/requests/api/v2/shared_examples/api_key_authenticatable'
require './spec/requests/api/v2/shared_examples/requests'

describe 'Specific Tube Creations API', with: :api_v2 do
  let(:model_class) { SpecificTubeCreation }
  let(:base_endpoint) { "/api/v2/#{resource_type}" }
  let(:resource_type) { model_class.name.demodulize.pluralize.underscore }

  it_behaves_like 'ApiKeyAuthenticatable'

  context 'with a list of resources' do
    let(:resource_count) { 5 }

    before { create_list(:specific_tube_creation, resource_count) }

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
      let(:resource) { create(:specific_tube_creation) }

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
          expect(json.dig('data', 'attributes', 'uuid')).to eq(resource.uuid)
        end

        it 'excludes unfetchable attributes' do
          expect(json.dig('data', 'attributes', 'child_purpose_uuids')).not_to be_present
          expect(json.dig('data', 'attributes', 'parent_uuids')).not_to be_present
          expect(json.dig('data', 'attributes', 'tube_attributes')).not_to be_present
        end

        it 'returns references to related resources' do
          expect(json.dig('data', 'relationships', 'children')).to be_present
          expect(json.dig('data', 'relationships', 'parents')).to be_present
          expect(json.dig('data', 'relationships', 'user')).to be_present
        end

        it 'does not include attributes for related resources' do
          expect(json['included']).not_to be_present
        end
      end

      context 'with included relationships' do
        it_behaves_like 'a GET request including a has_many relationship', 'children'
        it_behaves_like 'a GET request including a has_many relationship', 'parents'
        it_behaves_like 'a GET request including a has_one relationship', 'user'
      end
    end
  end

  describe '#PATCH a resource' do
    let(:resource_model) { create(:specific_tube_creation) }
    let(:purpose) { create(:tube_purpose) }
    let(:payload) do
      { data: { id: resource_model.id, type: resource_type, attributes: { child_purpose_uuids: [purpose.uuid] } } }
    end

    it 'finds no route for the method' do
      expect { api_patch "#{base_endpoint}/#{resource_model.id}", payload }.to raise_error(
        ActionController::RoutingError
      )
    end
  end

  describe '#POST a create request' do
    let(:child_purposes) { create_list(:tube_purpose, 2) }
    let(:parents) { [create(:plate), create(:tube, prefix: 'PT')] }
    let(:user) { create(:user) }

    let(:base_attributes) do
      { child_purpose_uuids: child_purposes.map(&:uuid), tube_attributes: [{ name: 'Tube one' }, { name: 'Tube two' }] }
    end

    let(:parents_relationship) { { data: parents.map { |p| { id: p.id, type: 'labware' } } } }
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

        it 'responds with the correct attributes' do
          new_record = model_class.last

          expect(json.dig('data', 'type')).to eq(resource_type)
          expect(json.dig('data', 'attributes', 'uuid')).to eq(new_record.uuid)
        end

        it 'excludes unfetchable attributes' do
          expect(json.dig('data', 'attributes', 'child_purpose_uuids')).not_to be_present
          expect(json.dig('data', 'attributes', 'parent_uuids')).not_to be_present
          expect(json.dig('data', 'attributes', 'tube_attributes')).not_to be_present
        end

        it 'returns references to related resources' do
          expect(json.dig('data', 'relationships', 'children')).to be_present
          expect(json.dig('data', 'relationships', 'parents')).to be_present
          expect(json.dig('data', 'relationships', 'user')).to be_present
        end

        it 'applies the attributes to the new record' do
          new_record = model_class.last

          # Note that the tube_attributes from the queried record will not match the submitted values, but it will
          # consist of empty hashes equalling the number of child purposes, as defined in the model.
          expect(new_record.tube_attributes).to eq(Array.new(child_purposes.length, {}))
        end

        it 'applies the relationships to the new record' do
          new_record = model_class.last

          expect(new_record.child_purposes).to eq(child_purposes)
          expect(new_record.parents).to eq(parents)
          expect(new_record.user).to eq(user)
        end

        it 'generated children with valid attributes' do
          new_record = model_class.last

          expect(new_record.children.length).to eq(2)
          expect(new_record.children.map(&:name)).to eq(['Tube one', 'Tube two'])
          expect(new_record.children.map(&:purpose)).to eq(child_purposes)
        end
      end

      context 'with complete attributes' do
        let(:payload) do
          {
            data: {
              type: resource_type,
              attributes:
                base_attributes.merge(
                  {
                    child_purpose_uuids: child_purposes.map(&:uuid),
                    parent_uuids: parents.map(&:uuid),
                    user_uuid: user.uuid
                  }
                )
            }
          }
        end

        it_behaves_like 'a valid request'
      end

      context 'with relationships' do
        let(:payload) do
          {
            data: {
              type: resource_type,
              attributes: base_attributes,
              relationships: {
                parents: parents_relationship,
                user: user_relationship
              }
            }
          }
        end

        it_behaves_like 'a valid request'
      end

      context 'with conflicting relationships' do
        let(:other_parents) { create_list(:plate, 2) }
        let(:other_user) { create(:user) }
        let(:payload) do
          {
            data: {
              type: resource_type,
              attributes:
                base_attributes.merge({ parent_uuids: other_parents.map(&:uuid), user_uuid: other_user.uuid }),
              relationships: {
                parents: parents_relationship,
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
        let(:payload) do
          {
            data: {
              type: resource_type,
              attributes: base_attributes.merge({ uuid: '111111-2222-3333-4444-555555666666' })
            }
          }
        end

        it_behaves_like 'a POST request with a disallowed value'
      end
    end

    context 'without a required relationship' do
      context 'without parent_uuids' do
        let(:error_detail_message) { "parent - can't be blank" }
        let(:payload) { { data: { type: resource_type, attributes: base_attributes.merge({ user_uuid: user.uuid }) } } }

        it_behaves_like 'an unprocessable POST request with a specific error'
      end

      context 'without user_uuid' do
        let(:error_detail_message) { "user - can't be blank" }
        let(:payload) do
          { data: { type: resource_type, attributes: base_attributes.merge({ parent_uuids: parents.map(&:uuid) }) } }
        end

        it_behaves_like 'an unprocessable POST request with a specific error'
      end

      context 'without parents' do
        let(:error_detail_message) { "parent - can't be blank" }
        let(:payload) do
          { data: { type: resource_type, attributes: base_attributes, relationships: { user: user_relationship } } }
        end

        it_behaves_like 'an unprocessable POST request with a specific error'
      end

      context 'without user' do
        let(:error_detail_message) { "user - can't be blank" }
        let(:payload) do
          {
            data: {
              type: resource_type,
              attributes: base_attributes,
              relationships: {
                parents: parents_relationship
              }
            }
          }
        end

        it_behaves_like 'an unprocessable POST request with a specific error'
      end
    end
  end

  context 'when DELETE request is unsuccessful' do
    let(:resource) { create(:specific_tube_creation) }

    it_behaves_like 'a DESTROY request for a v2 resource'
  end
end
