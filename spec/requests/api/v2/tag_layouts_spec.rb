# frozen_string_literal: true

require 'rails_helper'
require './spec/requests/api/v2/shared_examples/api_key_authenticatable'
require './spec/requests/api/v2/shared_examples/requests'

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
    let(:resource) { create(:tag_layout) }

    before { resource.update!(tag2_group: create(:tag_group_for_layout)) }

    describe '#GET resource by ID' do
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

        it_behaves_like 'a GET request including fetchable attribute', 'direction'
        it_behaves_like 'a GET request including fetchable attribute', 'initial_tag'
        it_behaves_like 'a GET request including fetchable attribute', 'substitutions'
        it_behaves_like 'a GET request including fetchable attribute', 'tags_per_well'
        it_behaves_like 'a GET request including fetchable attribute', 'walking_by'
        it_behaves_like 'a GET request including fetchable attribute', 'uuid'

        it_behaves_like 'a request excluding unfetchable attribute', 'plate_uuid'
        it_behaves_like 'a request excluding unfetchable attribute', 'tag_group_uuid'
        it_behaves_like 'a request excluding unfetchable attribute', 'tag2_group_uuid'
        it_behaves_like 'a request excluding unfetchable attribute', 'tag_layout_template_uuid'
        it_behaves_like 'a request excluding unfetchable attribute', 'user_uuid'

        it_behaves_like 'a request referencing a related resource', 'plate'
        it_behaves_like 'a request referencing a related resource', 'tag_group'
        it_behaves_like 'a request referencing a related resource', 'tag2_group'
        it_behaves_like 'a request referencing a related resource', 'user'

        it 'does not include attributes for related resources' do
          expect(json['included']).not_to be_present
        end
      end

      context 'with included relationships' do
        it_behaves_like 'a GET request including a has_one relationship', 'plate'
        it_behaves_like 'a GET request including a has_one relationship', 'tag_group'
        it_behaves_like 'a GET request including a has_one relationship', 'tag2_group'
        it_behaves_like 'a GET request including a has_one relationship', 'user'
      end
    end
  end

  describe '#PATCH a resource' do
    let(:resource_model) { create(:tag_layout) }
    let(:payload) { { data: { id: resource_model.id, type: resource_type, attributes: { direction: 'columns' } } } }

    it 'finds no route for the method' do
      expect { api_patch "#{base_endpoint}/#{resource_model.id}", payload }.to raise_error(
        ActionController::RoutingError
      )
    end
  end

  describe '#POST a create request' do
    let(:direction) { 'column' }
    let(:initial_tag) { 0 }
    let(:substitutions) { { 'A1' => 'B2' } }
    let(:tags_per_well) { 1 } # Ignored by the walking_by algorithm below
    let(:walking_by) { 'wells of plate' }

    let(:base_attributes) { { direction:, initial_tag:, substitutions:, tags_per_well:, walking_by: } }

    let(:plate) { create(:plate) }
    let(:tag_group) { create(:tag_group_for_layout) }
    let(:tag2_group) { create(:tag_group_for_layout) }
    let(:user) { create(:user) }

    let(:plate_relationship) { { data: { id: plate.id, type: 'plates' } } }
    let(:tag_group_relationship) { { data: { id: tag_group.id, type: 'tag_groups' } } }
    let(:tag2_group_relationship) { { data: { id: tag2_group.id, type: 'tag_groups' } } }
    let(:user_relationship) { { data: { id: user.id, type: 'users' } } }

    context 'with a valid payload without a template' do
      shared_examples 'a valid request without a template' do
        before { api_post base_endpoint, payload }

        it 'creates a new resource' do
          expect { api_post base_endpoint, payload }.to change(model_class, :count).by(1)
        end

        it 'responds with a success http code' do
          expect(response).to have_http_status(:success)
        end

        it 'returns the resource with the correct type' do
          expect(json.dig('data', 'type')).to eq(resource_type)
        end

        it_behaves_like 'a POST request including model attribute', TagLayout, 'direction'
        it_behaves_like 'a POST request including model attribute', TagLayout, 'initial_tag'
        it_behaves_like 'a POST request including model attribute', TagLayout, 'substitutions'
        it_behaves_like 'a POST request including model attribute', TagLayout, 'walking_by'
        it_behaves_like 'a POST request including model attribute', TagLayout, 'uuid'

        it "responds with the supplied 'tags_per_well' attribute value" do
          # Note that the tags per well will not be saved with the record as it isn't a stored attribute in the
          # database. The response is based on the model after being saved, which still holds the value given in the
          # payload.
          expect(json.dig('data', 'attributes', 'tags_per_well')).to eq(payload.dig(:data, :attributes, :tags_per_well))
        end

        it_behaves_like 'a request excluding unfetchable attribute', 'plate_uuid'
        it_behaves_like 'a request excluding unfetchable attribute', 'tag_group_uuid'
        it_behaves_like 'a request excluding unfetchable attribute', 'tag2_group_uuid'
        it_behaves_like 'a request excluding unfetchable attribute', 'tag_layout_template_uuid'
        it_behaves_like 'a request excluding unfetchable attribute', 'user_uuid'

        it "updates the model with the new 'direction' attribute value" do
          expect(model_class.last.direction).to eq(direction)
        end

        it "updates the model with the new 'initial_tag' attribute value" do
          expect(model_class.last.initial_tag).to eq(initial_tag)
        end

        it "updates the model with the new 'substitutions' attribute value" do
          expect(model_class.last.substitutions).to eq(substitutions)
        end

        it "updates the model with the new 'walking_by' attribute value" do
          expect(model_class.last.walking_by).to eq(walking_by)
        end

        it "responds with nil for the 'tags_per_well' attribute" do
          # Note that the tags_per_well from the queried record will be nil as it isn't a stored attribute in the
          # database.
          expect(model_class.last.tags_per_well).to be_nil
        end

        it_behaves_like 'a request referencing a related resource', 'plate'
        it_behaves_like 'a request referencing a related resource', 'tag_group'
        it_behaves_like 'a request referencing a related resource', 'tag2_group'
        it_behaves_like 'a request referencing a related resource', 'user'

        it "updates the model with the new 'plate' relationship" do
          expect(model_class.last.plate).to eq(plate)
        end

        it "updates the model with the new 'tag_group' relationship" do
          expect(model_class.last.tag_group).to eq(tag_group)
        end

        it "updates the model with the new 'tag2_group' relationship" do
          expect(model_class.last.tag2_group).to eq(tag2_group)
        end

        it "updates the model with the new 'user' relationship" do
          expect(model_class.last.user).to eq(user)
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

        it_behaves_like 'a valid request without a template'
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

        it_behaves_like 'a valid request without a template'
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
        it_behaves_like 'a valid request without a template'
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

    context 'without a required attribute' do
      context 'without direction' do
        let(:error_detail_message) { 'direction - must define a valid algorithm' }
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

        it_behaves_like 'an unprocessable POST request with a specific error'
      end

      context 'without walking_by' do
        let(:error_detail_message) { 'walking_by - must define a valid algorithm' }
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

        it_behaves_like 'an unprocessable POST request with a specific error'
      end
    end

    context 'with an invalid attribute value' do
      context 'with an invalid direction' do
        let(:error_detail_message) { 'direction - must define a valid algorithm' }
        let(:payload) do
          {
            data: {
              type: resource_type,
              attributes:
                base_attributes.merge(
                  { direction: '1', plate_uuid: plate.uuid, tag_group_uuid: tag_group.uuid, user_uuid: user.uuid }
                )
            }
          }
        end

        it_behaves_like 'an unprocessable POST request with a specific error'
      end

      context 'with an invalid walking_by' do
        let(:error_detail_message) { 'walking_by - must define a valid algorithm' }
        let(:payload) do
          {
            data: {
              type: resource_type,
              attributes:
                base_attributes.merge(
                  { walking_by: '1', plate_uuid: plate.uuid, tag_group_uuid: tag_group.uuid, user_uuid: user.uuid }
                )
            }
          }
        end

        it_behaves_like 'an unprocessable POST request with a specific error'
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

        it_behaves_like 'an unprocessable POST request with a specific error'
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

        it_behaves_like 'an unprocessable POST request with a specific error'
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

        it_behaves_like 'an unprocessable POST request with a specific error'
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

        it_behaves_like 'an unprocessable POST request with a specific error'
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

        it_behaves_like 'an unprocessable POST request with a specific error'
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

        it_behaves_like 'an unprocessable POST request with a specific error'
      end
    end
  end
end
