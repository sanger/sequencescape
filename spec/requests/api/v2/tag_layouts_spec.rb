# frozen_string_literal: true

require 'rails_helper'
require './spec/requests/api/v2/shared_examples/api_key_authenticatable'
require './spec/requests/api/v2/shared_examples/post_requests'

describe 'Tag Layouts API', with: :api_v2 do
  let(:model_class) { TagLayout }
  let(:base_endpoint) { "/api/v2/#{resource_type}" }
  let(:resource_type) { model_class.name.demodulize.pluralize.underscore }

  it_behaves_like 'ApiKeyAuthenticatable'

  context 'with a list of resources' do
    let(:resource_count) { 5 }

    before { create_list(:tag_layout, resource_count) }

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
      let(:resource) { create :tag_layout }

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
          expect(json.dig('data', 'attributes', 'direction')).to eq(resource.direction)
          expect(json.dig('data', 'attributes', 'initial_tag')).to eq(resource.initial_tag)
          expect(json.dig('data', 'attributes', 'substitutions')).to eq(resource.substitutions)
          expect(json.dig('data', 'attributes', 'tags_per_well')).to eq(resource.tags_per_well)
          expect(json.dig('data', 'attributes', 'walking_by')).to eq(resource.walking_by)
          expect(json.dig('data', 'attributes', 'uuid')).to eq(resource.uuid)
        end

        it 'excludes unfetchable attributes' do
          expect(json.dig('data', 'attributes', 'plate_uuid')).not_to be_present
          expect(json.dig('data', 'attributes', 'tag_group_uuid')).not_to be_present
          expect(json.dig('data', 'attributes', 'tag2_group_uuid')).not_to be_present
          expect(json.dig('data', 'attributes', 'user_uuid')).not_to be_present
        end

        it 'returns references to related resources' do
          expect(json.dig('data', 'relationships', 'plate')).to be_present
          expect(json.dig('data', 'relationships', 'tag_group')).to be_present
          expect(json.dig('data', 'relationships', 'tag2_group')).to be_present
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
    let(:resource_model) { create :tag_layout }
    let(:payload) { { data: { id: resource_model.id, type: resource_type, attributes: { direction: 'columns' } } } }

    it 'finds no route for the method' do
      expect { api_patch "#{base_endpoint}/#{resource_model.id}", payload }.to raise_error(
        ActionController::RoutingError
      )
    end
  end

  describe '#POST a create request' do
    let(:plate) { create(:plate) }
    let(:tag_group) { create(:tag_group) }
    let(:tag2_group) { create(:tag_group) }
    let(:user) { create(:user) }

    let(:base_attributes) do
      {
        direction: 'column',
        initial_tag: 0,
        substitutions: {
          'A1' => 'B2'
        },
        tags_per_well: 1, # Ignored by the walking_by algorithm below
        walking_by: 'wells of plate'
      }
    end

    let(:plate_relationship) { { data: { id: plate.id, type: 'plates' } } }
    let(:tag_group_relationship) { { data: { id: tag_group.id, type: 'tag_groups' } } }
    let(:tag2_group_relationship) { { data: { id: tag2_group.id, type: 'tag_groups' } } }
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
          expect(json.dig('data', 'attributes', 'direction')).to eq(new_record.direction)
          expect(json.dig('data', 'attributes', 'initial_tag')).to eq(new_record.initial_tag)
          expect(json.dig('data', 'attributes', 'substitutions')).to eq(new_record.substitutions)
          expect(json.dig('data', 'attributes', 'walking_by')).to eq(new_record.walking_by)
          expect(json.dig('data', 'attributes', 'uuid')).to eq(new_record.uuid)

          # Note that the tags per well will not be saved with the record as it isn't a stored attribute in the
          # database. The response is based on the model after being saved, which still holds the value given in the
          # payload.
          expect(json.dig('data', 'attributes', 'tags_per_well')).to eq(payload.dig(:data, :attributes, :tags_per_well))
        end

        it 'excludes unfetchable attributes' do
          expect(json.dig('data', 'attributes', 'plate_uuid')).not_to be_present
          expect(json.dig('data', 'attributes', 'tag_group_uuid')).not_to be_present
          expect(json.dig('data', 'attributes', 'tag2_group_uuid')).not_to be_present
          expect(json.dig('data', 'attributes', 'user_uuid')).not_to be_present
        end

        it 'returns references to related resources' do
          expect(json.dig('data', 'relationships', 'plate')).to be_present
          expect(json.dig('data', 'relationships', 'tag_group')).to be_present
          expect(json.dig('data', 'relationships', 'tag2_group')).to be_present
          expect(json.dig('data', 'relationships', 'user')).to be_present
        end

        it 'applies the attributes to the new record' do
          new_record = model_class.last

          expect(new_record.direction).to eq(payload.dig(:data, :attributes, :direction))
          expect(new_record.initial_tag).to eq(payload.dig(:data, :attributes, :initial_tag))
          expect(new_record.substitutions).to eq(payload.dig(:data, :attributes, :substitutions))
          expect(new_record.walking_by).to eq(payload.dig(:data, :attributes, :walking_by))

          # Note that the tags_per_well from the quieried record will be nil as it isn't a stored attribute in the
          # database.
          expect(new_record.tags_per_well).to be_nil
        end

        it 'applies the relationships to the new record' do
          new_record = model_class.last

          expect(new_record.plate).to eq(plate)
          expect(new_record.tag_group).to eq(tag_group)
          expect(new_record.tag2_group).to eq(tag2_group)
          expect(new_record.user).to eq(user)
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
                    plate_uuid: plate.uuid,
                    tag_group_uuid: tag_group.uuid,
                    tag2_group_uuid: tag2_group.uuid,
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
                plate: plate_relationship,
                tag_group: tag_group_relationship,
                tag2_group: tag2_group_relationship,
                user: user_relationship
              }
            }
          }
        end

        it_behaves_like 'a valid request'
      end

      context 'with conflicting relationships' do
        let(:other_plate) { create(:plate) }
        let(:other_tag_group) { create(:tag_group) }
        let(:other_tag2_group) { create(:tag_group) }
        let(:other_user) { create(:user) }
        let(:payload) do
          {
            data: {
              type: resource_type,
              attributes:
                base_attributes.merge(
                  {
                    plate_uuid: other_plate.uuid,
                    tag_group_uuid: other_tag_group.uuid,
                    tag2_group_uuid: other_tag2_group.uuid,
                    user_uuid: other_user.uuid
                  }
                ),
              relationships: {
                plate: plate_relationship,
                tag_group: tag_group_relationship,
                tag2_group: tag2_group_relationship,
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
        let(:disallowed_attribute) { 'uuid' }
        let(:payload) do
          {
            data: {
              type: resource_type,
              attributes: base_attributes.merge({ uuid: '111111-2222-3333-4444-555555666666' })
            }
          }
        end

        it_behaves_like 'a POST request with a disallowed attribute'
      end
    end

    context 'without a required attribute' do
      context 'without direction' do
        let(:error_detail_message) { "direction - can't be blank" }
        let(:payload) do
          {
            data: {
              type: resource_type,
              attributes:
                base_attributes.merge(
                  { direction: nil, plate_uuid: plate.uuid, tag_group_uuid: tag_group.uuid, user_uuid: user.uuid }
                )
            }
          }
        end

        it_behaves_like 'a POST request with a missing attribute'
      end

      context 'without walking_by' do
        let(:error_detail_message) { "walking_by - can't be blank" }
        let(:payload) do
          {
            data: {
              type: resource_type,
              attributes:
                base_attributes.merge(
                  { walking_by: nil, plate_uuid: plate.uuid, tag_group_uuid: tag_group.uuid, user_uuid: user.uuid }
                )
            }
          }
        end

        it_behaves_like 'a POST request with a missing attribute'
      end
    end

    context 'without a required relationship' do
      context 'without plate_uuid' do
        let(:error_detail_message) { 'plate - must exist' }
        let(:payload) do
          {
            data: {
              type: resource_type,
              attributes: base_attributes.merge({ tag_group_uuid: tag_group.uuid, user_uuid: user.uuid })
            }
          }
        end

        it_behaves_like 'a POST request without a required relationship'
      end

      context 'without tag_group_uuid' do
        let(:error_detail_message) { 'tag_group - must exist' }
        let(:payload) do
          {
            data: {
              type: resource_type,
              attributes: base_attributes.merge({ plate_uuid: plate.uuid, user_uuid: user.uuid })
            }
          }
        end

        it_behaves_like 'a POST request without a required relationship'
      end

      context 'without user_uuid' do
        let(:error_detail_message) { 'user - must exist' }
        let(:payload) do
          {
            data: {
              type: resource_type,
              attributes: base_attributes.merge({ plate_uuid: plate.uuid, tag_group_uuid: tag_group.uuid })
            }
          }
        end

        it_behaves_like 'a POST request without a required relationship'
      end

      context 'without plate' do
        let(:error_detail_message) { 'plate - must exist' }
        let(:payload) do
          {
            data: {
              type: resource_type,
              attributes: base_attributes,
              relationships: {
                tag_group: tag_group_relationship,
                user: user_relationship
              }
            }
          }
        end

        it_behaves_like 'a POST request without a required relationship'
      end

      context 'without tag_group' do
        let(:error_detail_message) { 'tag_group - must exist' }
        let(:payload) do
          {
            data: {
              type: resource_type,
              attributes: base_attributes,
              relationships: {
                plate: plate_relationship,
                user: user_relationship
              }
            }
          }
        end

        it_behaves_like 'a POST request without a required relationship'
      end

      context 'without user' do
        let(:error_detail_message) { 'user - must exist' }
        let(:payload) do
          {
            data: {
              type: resource_type,
              attributes: base_attributes,
              relationships: {
                plate: plate_relationship,
                tag_group: tag_group_relationship
              }
            }
          }
        end

        it_behaves_like 'a POST request without a required relationship'
      end
    end
  end
end
