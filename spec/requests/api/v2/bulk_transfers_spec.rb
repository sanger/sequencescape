# frozen_string_literal: true

require 'rails_helper'
require './spec/requests/api/v2/shared_examples/api_key_authenticatable'
require './spec/requests/api/v2/shared_examples/requests'

describe 'Bulk Transfer API', with: :api_v2 do
  let(:model_class) { BulkTransfer }
  let(:base_endpoint) { "/api/v2/#{resource_type}" }
  let(:resource_type) { model_class.name.demodulize.pluralize.underscore }

  it_behaves_like 'ApiKeyAuthenticatable'

  context 'with a list of resources' do
    let(:resource_count) { 5 }

    before { create_list(:bulk_transfer, resource_count) }

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
      let(:resource) { create(:bulk_transfer) }

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

        it 'excludes the unfetchable well_transfers' do
          expect(json.dig('data', 'attributes', 'well_transfers')).not_to be_present
        end

        it 'excludes the unfetchable user_uuid' do
          expect(json.dig('data', 'attributes', 'user_uuid')).not_to be_present
        end

        it 'returns a reference to the transfers relationship' do
          expect(json.dig('data', 'relationships', 'transfers')).to be_present
        end

        it 'returns a reference to the user relationship' do
          expect(json.dig('data', 'relationships', 'user')).to be_present
        end

        it 'does not include attributes for related resources' do
          expect(json['included']).not_to be_present
        end
      end

      context 'with included relationships' do
        it_behaves_like 'a GET request including a has_many relationship', 'transfers'
        it_behaves_like 'a GET request including a has_one relationship', 'user'
      end
    end
  end

  describe '#PATCH a resource' do
    let(:resource_model) { create(:bulk_transfer) }
    let(:payload) { { data: { id: resource_model.id, type: resource_type, attributes: {} } } }

    it 'finds no route for the method' do
      expect { api_patch "#{base_endpoint}/#{resource_model.id}", payload }.to raise_error(
        ActionController::RoutingError
      )
    end
  end

  describe '#POST a create request' do
    let(:src_plates) { create_list(:transfer_plate, 2) }
    let(:dest_plates) { create_list(:plate_with_empty_wells, 2) }
    let(:transfer_ordered_src_plates) { [src_plates[0], src_plates[0], src_plates[1], src_plates[1]] }
    let(:transfer_ordered_dest_plates) { [dest_plates[0], dest_plates[1], dest_plates[0], dest_plates[1]] }
    let(:transfer_ordered_locations) do
      [{ 'A1' => ['A1'] }, { 'B1' => ['A1'] }, { 'A1' => ['B1'] }, { 'B1' => ['B1'] }]
    end
    let(:well_transfers) do
      [
        {
          'source_uuid' => transfer_ordered_src_plates[0].uuid,
          'source_location' => transfer_ordered_locations[0].keys.first,
          'destination_uuid' => transfer_ordered_dest_plates[0].uuid,
          'destination_location' => transfer_ordered_locations[0].values.first.first
        },
        {
          'source_uuid' => transfer_ordered_src_plates[1].uuid,
          'source_location' => transfer_ordered_locations[1].keys.first,
          'destination_uuid' => transfer_ordered_dest_plates[1].uuid,
          'destination_location' => transfer_ordered_locations[1].values.first.first
        },
        {
          'source_uuid' => transfer_ordered_src_plates[2].uuid,
          'source_location' => transfer_ordered_locations[2].keys.first,
          'destination_uuid' => transfer_ordered_dest_plates[2].uuid,
          'destination_location' => transfer_ordered_locations[2].values.first.first
        },
        {
          'source_uuid' => transfer_ordered_src_plates[3].uuid,
          'source_location' => transfer_ordered_locations[3].keys.first,
          'destination_uuid' => transfer_ordered_dest_plates[3].uuid,
          'destination_location' => transfer_ordered_locations[3].values.first.first
        }
      ]
    end

    let(:user) { create(:user) }

    let(:user_relationship) { { data: { id: user.id, type: 'users' } } }

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
          expect(json.dig('data', 'attributes', 'uuid')).to eq(new_record.uuid)
        end

        it 'excludes the unfetchable user_uuid' do
          perform_request
          expect(json.dig('data', 'attributes', 'user_uuid')).not_to be_present
        end

        it 'excludes the unfetchable well_transfers' do
          perform_request
          expect(json.dig('data', 'attributes', 'well_transfers')).not_to be_present
        end

        it 'returns a reference to the transfers relationship' do
          perform_request
          expect(json.dig('data', 'relationships', 'transfers')).to be_present
        end

        it 'returns a reference to the user relationship' do
          perform_request
          expect(json.dig('data', 'relationships', 'user')).to be_present
        end

        it 'responds with the correct number of transfers' do
          perform_request
          new_record = model_class.last
          expect(new_record.transfers.count).to eq(4)
        end

        it 'associates the user with the new record' do
          perform_request
          new_record = model_class.last
          expect(new_record.user).to eq(user)
        end

        it 'generates the correct number of transfers' do
          perform_request
          expect(Transfer::BetweenPlates.count).to eq(4)
        end

        it 'generates transfers with the correct sources' do
          perform_request
          expect(Transfer::BetweenPlates.all.map(&:source)).to match_array(transfer_ordered_src_plates)
        end

        it 'generates transfers with the correct destinations' do
          perform_request
          expect(Transfer::BetweenPlates.all.map(&:destination)).to match_array(transfer_ordered_dest_plates)
        end

        it 'generates transfers with the correct transfers hashes' do
          perform_request
          expect(Transfer::BetweenPlates.all.map(&:transfers_hash)).to match_array(transfer_ordered_locations)
        end
      end

      context 'with complete attributes' do
        let(:payload) do
          { data: { type: resource_type, attributes: { user_uuid: user.uuid, well_transfers: well_transfers } } }
        end

        it_behaves_like 'a valid request'
      end

      context 'with user as a relationship' do
        let(:payload) do
          { data: { type: resource_type, attributes: { well_transfers: }, relationships: { user: user_relationship } } }
        end

        it_behaves_like 'a valid request'
      end

      context 'with conflicting user definitions' do
        let(:other_user) { create(:user) }
        let(:payload) do
          {
            data: {
              type: resource_type,
              attributes: {
                well_transfers: well_transfers,
                user_uuid: other_user.uuid
              },
              relationships: {
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
      context 'without a user or user_uuid' do
        let(:error_detail_message) { "user - can't be blank" }
        let(:payload) { { data: { type: resource_type, attributes: { well_transfers: } } } }

        it_behaves_like 'an unprocessable POST request with a specific error'
      end
    end
  end
end
