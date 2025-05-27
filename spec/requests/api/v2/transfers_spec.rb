# frozen_string_literal: true

require 'rails_helper'
require './spec/requests/api/v2/shared_examples/api_key_authenticatable'
require './spec/requests/api/v2/shared_examples/requests'

describe 'Transfer API', with: :api_v2 do
  let(:model_class) { Transfer::BetweenPlates }
  let(:base_endpoint) { '/api/v2/transfers' }
  let(:resource_type) { 'transfers' }

  it_behaves_like 'ApiKeyAuthenticatable'

  context 'with a list of resources' do
    let(:filtered_type_count) { 5 }
    let(:other_type_count) { 3 }

    before do
      create_list(:transfer_between_plates, filtered_type_count)
      create_list(:transfer_from_plate_to_tube, other_type_count)
    end

    describe '#GET all resources' do
      before { api_get base_endpoint }

      it 'responds with a success http code' do
        expect(response).to have_http_status(:success)
      end

      it 'returns all the resources' do
        expect(json['data'].length).to eq(filtered_type_count + other_type_count)
      end
    end

    describe '#GET filtered resources' do
      before { api_get base_endpoint + "?filter[transfer_type]=#{model_class}" }

      it 'responds with a success http code' do
        expect(response).to have_http_status(:success)
      end

      it 'returns all the resources' do
        expect(json['data'].length).to eq(filtered_type_count)
      end
    end
  end

  context 'with a single resource' do
    describe '#GET resource by ID' do
      let(:resource) { create(:transfer_between_plates) }

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
          expect(json.dig('data', 'attributes', 'destination_uuid')).to eq(resource.destination.uuid)
          expect(json.dig('data', 'attributes', 'source_uuid')).to eq(resource.source.uuid)
          expect(json.dig('data', 'attributes', 'transfer_type')).to eq(model_class.to_s)
          expect(json.dig('data', 'attributes', 'transfers')).to eq(resource.transfers)
          expect(json.dig('data', 'attributes', 'user_uuid')).to eq(resource.user.uuid)
          expect(json.dig('data', 'attributes', 'uuid')).to eq(resource.uuid)
        end

        it 'excludes the unfetchable transfer_template_uuid' do
          expect(json.dig('data', 'attributes', 'transfer_template_uuid')).not_to be_present
        end

        it 'returns a reference to the destination relationship' do
          expect(json.dig('data', 'relationships', 'destination')).to be_present
        end

        it 'returns a reference to the source relationship' do
          expect(json.dig('data', 'relationships', 'source')).to be_present
        end

        it 'returns a reference to the user relationship' do
          expect(json.dig('data', 'relationships', 'user')).to be_present
        end

        it 'does not include attributes for related resources' do
          expect(json['included']).not_to be_present
        end
      end

      context 'with included relationships' do
        it_behaves_like 'a GET request including a has_one relationship', 'user'
      end
    end
  end

  # Some old data may not have a User relationship even though it's required for new records.
  # Note that the user relationship will still be shown in the response.  We're only checking that the response
  # is successful and contains expected attributes.
  context 'with a single resource without a User relationship' do
    describe '#GET resource by ID' do
      let(:resource) { create(:transfer_between_plates) }

      before do
        # We need to remove the user relationship without invoking validations.
        # The validations prevent new records from being created without a User.
        resource.user = nil
        resource.save(validate: false)

        api_get "#{base_endpoint}/#{resource.id}"
      end

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
        expect(json.dig('data', 'attributes', 'destination_uuid')).to eq(resource.destination.uuid)
        expect(json.dig('data', 'attributes', 'source_uuid')).to eq(resource.source.uuid)
        expect(json.dig('data', 'attributes', 'transfer_type')).to eq(model_class.to_s)
        expect(json.dig('data', 'attributes', 'transfers')).to eq(resource.transfers)
        expect(json.dig('data', 'attributes', 'user_uuid')).to be_nil
        expect(json.dig('data', 'attributes', 'uuid')).to eq(resource.uuid)
      end
    end
  end

  describe '#PATCH a resource' do
    let(:resource_model) { create(:transfer_between_plates) }
    let(:purpose) { create(:tube_purpose) }
    let(:payload) do
      { data: { id: resource_model.id, type: resource_type, attributes: { child_purpose_uuid: [purpose.uuid] } } }
    end

    it 'finds no route for the method' do
      expect { api_patch "#{base_endpoint}/#{resource_model.id}", payload }.to raise_error(
        ActionController::RoutingError
      )
    end
  end

  describe '#POST a create request' do
    let(:destination) { create(:plate_with_empty_wells) }
    let(:source) { create(:transfer_plate) }
    let(:transfer_template) { create(:transfer_template) } # BetweenPlates
    let(:user) { create(:user) }

    let(:destination_relationship) { { data: { id: destination.id, type: 'labware' } } }
    let(:source_relationship) { { data: { id: source.id, type: 'labware' } } }
    let(:user_relationship) { { data: { id: user.id, type: 'users' } } }

    let(:all_attributes) do
      {
        destination_uuid: destination.uuid,
        source_uuid: source.uuid,
        transfer_template_uuid: transfer_template.uuid,
        user_uuid: user.uuid
      }
    end
    let(:all_relationships) do
      { destination: destination_relationship, source: source_relationship, user: user_relationship }
    end

    context 'with a valid payload' do
      shared_examples 'a valid request' do
        # We can't perform the request in a `before` block because it can only be submitted once and some tests need to
        # confirm expectations before the request is made.
        def perform_request
          api_post base_endpoint, payload
        end

        it 'creates a new resource' do
          expect { perform_request }.to change(model_class, :count).by(1)
        end

        it 'responds with success' do
          perform_request
          expect(response).to have_http_status(:success)
        end

        it 'responds with a resource of the correct type' do
          perform_request
          expect(json.dig('data', 'type')).to eq(resource_type)
        end

        it 'responds with a uuid matching the new record' do
          perform_request
          new_record = model_class.last
          expect(json.dig('data', 'attributes', 'destination_uuid')).to eq(new_record.destination.uuid)
          expect(json.dig('data', 'attributes', 'source_uuid')).to eq(new_record.source.uuid)
          expect(json.dig('data', 'attributes', 'transfer_type')).to eq(model_class.to_s)
          expect(json.dig('data', 'attributes', 'transfers')).to eq(new_record.transfers)
          expect(json.dig('data', 'attributes', 'user_uuid')).to eq(new_record.user.uuid)
          expect(json.dig('data', 'attributes', 'uuid')).to eq(new_record.uuid)
        end

        it 'excludes the unfetchable transfer_template_uuid' do
          perform_request
          expect(json.dig('data', 'attributes', 'transfer_template_uuid')).not_to be_present
        end

        it 'returns a reference to the destination relationship' do
          perform_request
          expect(json.dig('data', 'relationships', 'destination')).to be_present
        end

        it 'returns a reference to the source relationship' do
          perform_request
          expect(json.dig('data', 'relationships', 'source')).to be_present
        end

        it 'returns a reference to the user relationship' do
          perform_request
          expect(json.dig('data', 'relationships', 'user')).to be_present
        end

        it 'associates the destination with the new record' do
          perform_request
          new_record = model_class.last
          expect(new_record.destination).to eq(destination)
        end

        it 'associates the source with the new record' do
          perform_request
          new_record = model_class.last
          expect(new_record.source).to eq(source)
        end

        it 'associates the user with the new record' do
          perform_request
          new_record = model_class.last
          expect(new_record.user).to eq(user)
        end
      end

      context 'with only attributes' do
        let(:payload) { { data: { type: resource_type, attributes: all_attributes } } }

        it_behaves_like 'a valid request'
      end

      context 'with destination as a relationship' do
        let(:payload) do
          {
            data: {
              type: resource_type,
              attributes: all_attributes.merge(destination_uuid: nil),
              relationships: {
                destination: destination_relationship
              }
            }
          }
        end

        it_behaves_like 'a valid request'
      end

      context 'with source as a relationship' do
        let(:payload) do
          {
            data: {
              type: resource_type,
              attributes: all_attributes.merge(source_uuid: nil),
              relationships: {
                source: source_relationship
              }
            }
          }
        end

        it_behaves_like 'a valid request'
      end

      context 'with user as a relationship' do
        let(:payload) do
          {
            data: {
              type: resource_type,
              attributes: all_attributes.merge(user_uuid: nil),
              relationships: {
                user: user_relationship
              }
            }
          }
        end

        it_behaves_like 'a valid request'
      end

      context 'with conflicting attributes and relationships definitions' do
        let(:other_destination) { create(:plate_with_empty_wells) }
        let(:other_source) { create(:transfer_plate) }
        let(:other_user) { create(:user) }
        let(:payload) do
          {
            data: {
              type: resource_type,
              attributes:
                all_attributes.merge(
                  destination_uuid: other_destination.uuid,
                  source_uuid: other_source.uuid,
                  user_uuid: other_user.uuid
                ),
              relationships: all_relationships
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
      context 'without a source or source_uuid' do
        let(:error_detail_message) { "source - can't be blank" }
        let(:payload) do
          {
            data: {
              type: resource_type,
              attributes: all_attributes.merge(source_uuid: nil),
              relationships: all_relationships.merge(source: nil)
            }
          }
        end

        it_behaves_like 'an unprocessable POST request with a specific error'
      end

      context 'without a user or user_uuid' do
        let(:error_detail_message) { "user - can't be blank" }
        let(:payload) do
          {
            data: {
              type: resource_type,
              attributes: all_attributes.merge(user_uuid: nil),
              relationships: all_relationships.merge(user: nil)
            }
          }
        end

        it_behaves_like 'an unprocessable POST request with a specific error'
      end
    end
  end

  context 'when DELETE request is unsuccessful' do
    let(:resource) { create(:transfer_between_plates) }

    it_behaves_like 'a DESTROY request for a v2 resource'
  end
end
