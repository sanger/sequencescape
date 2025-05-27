# frozen_string_literal: true

require 'rails_helper'
require './spec/requests/api/v2/shared_examples/api_key_authenticatable'
require './spec/requests/api/v2/shared_examples/requests'

describe 'Transfer Request Collection API', with: :api_v2 do
  let(:model_class) { TransferRequestCollection }
  let(:base_endpoint) { "/api/v2/#{resource_type}" }
  let(:resource_type) { model_class.name.demodulize.pluralize.underscore }

  it_behaves_like 'ApiKeyAuthenticatable'

  context 'with a list of resources' do
    let(:resource_count) { 5 }

    before { create_list(:transfer_request_collection, resource_count) }

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
      let(:resource) { create(:transfer_request_collection) }

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
          expect(json.dig('data', 'attributes', 'transfer_requests_attributes')).not_to be_present
          expect(json.dig('data', 'attributes', 'user_uuid')).not_to be_present
        end

        it 'returns references to related resources' do
          expect(json.dig('data', 'relationships', 'target_tubes')).to be_present
          expect(json.dig('data', 'relationships', 'transfer_requests')).to be_present
          expect(json.dig('data', 'relationships', 'user')).to be_present
        end

        it 'does not include attributes for related resources' do
          expect(json['included']).not_to be_present
        end
      end

      context 'with included relationships' do
        it_behaves_like 'a GET request including a has_many relationship', 'target_tubes'
        it_behaves_like 'a GET request including a has_many relationship', 'transfer_requests'
        it_behaves_like 'a GET request including a has_one relationship', 'user'
      end
    end
  end

  describe '#PATCH a resource' do
    let(:resource_model) { create(:transfer_request_collection) }
    let(:payload) { { data: { id: resource_model.id, type: resource_type, attributes: { user_uuid: '1' } } } }

    it 'finds no route for the method' do
      expect { api_patch "#{base_endpoint}/#{resource_model.id}", payload }.to raise_error(
        ActionController::RoutingError
      )
    end
  end

  describe '#POST a create request' do
    let(:user) { create(:user) }
    let(:user_relationship) { { data: { id: user.id, type: 'users' } } }

    let(:source_assets) { create_list(:receptacle, 2) }
    let(:target_tubes) { create_list(:stock_multiplexed_library_tube, 2) }
    let(:target_assets) { target_tubes.map { |tube| create(:receptacle, labware: tube) } }
    let(:transfer_requests_attributes) do
      source_assets
        .zip(target_assets)
        .map { |source_asset, target_asset| { source_asset: source_asset.uuid, target_asset: target_asset.uuid } }
    end

    let(:base_attributes) { { transfer_requests_attributes: } }

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
          expect(json.dig('data', 'attributes', 'transfer_requests_attributes')).not_to be_present
          expect(json.dig('data', 'attributes', 'user_uuid')).not_to be_present
        end

        it 'returns references to related resources' do
          expect(json.dig('data', 'relationships', 'target_tubes')).to be_present
          expect(json.dig('data', 'relationships', 'transfer_requests')).to be_present
          expect(json.dig('data', 'relationships', 'user')).to be_present
        end

        it 'applies the relationships to the new record' do
          new_record = model_class.last

          expect(new_record.user).to eq(user)
        end

        it 'generated expected TransferRequests' do
          new_record = model_class.last

          expect(new_record.transfer_requests.count).to eq(transfer_requests_attributes.count)
          expect(new_record.transfer_requests.map(&:asset)).to match_array(source_assets)
          expect(new_record.transfer_requests.map(&:target_asset)).to match_array(target_assets)
        end

        it 'populates the target_tubes relationship' do
          new_record = model_class.last

          expect(new_record.target_tubes).to match_array(target_tubes)
        end
      end

      context 'with complete attributes' do
        let(:payload) { { data: { type: resource_type, attributes: base_attributes.merge({ user_uuid: user.uuid }) } } }

        it_behaves_like 'a valid request'
      end

      context 'with relationships' do
        let(:payload) do
          { data: { type: resource_type, attributes: base_attributes, relationships: { user: user_relationship } } }
        end

        it_behaves_like 'a valid request'
      end

      context 'with conflicting relationships' do
        let(:other_user) { create(:user) }
        let(:payload) do
          {
            data: {
              type: resource_type,
              attributes: base_attributes.merge({ user_uuid: other_user.uuid }),
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

    context 'with a read-only relationship in the payload' do
      context 'with target_tubes' do
        let(:disallowed_value) { 'target_tubes' }
        let(:payload) do
          {
            data: {
              type: resource_type,
              attributes: base_attributes,
              relationships: {
                target_tubes: [{ data: { id: '1', type: 'tubes' } }]
              }
            }
          }
        end

        it_behaves_like 'a POST request with a disallowed value'
      end

      context 'with transfer_requests' do
        let(:disallowed_value) { 'transfer_requests' }
        let(:payload) do
          {
            data: {
              type: resource_type,
              attributes: base_attributes,
              relationships: {
                transfer_requests: [{ data: { id: '1', type: 'transfer_requests' } }]
              }
            }
          }
        end

        it_behaves_like 'a POST request with a disallowed value'
      end
    end

    context 'without a required relationship' do
      context 'without a user or user_uuid' do
        let(:error_detail_message) { 'user - must exist' }
        let(:payload) { { data: { type: resource_type, attributes: base_attributes } } }

        it_behaves_like 'an unprocessable POST request with a specific error'
      end
    end
  end

  context 'when DELETE request is unsuccessful' do
    let(:resource) { create(:transfer_request_collection) }

    it_behaves_like 'a DESTROY request for a v2 resource'
  end
end
