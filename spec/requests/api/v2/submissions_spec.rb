# frozen_string_literal: true

require 'rails_helper'
require './spec/requests/api/v2/shared_examples/api_key_authenticatable'
require './spec/requests/api/v2/shared_examples/requests'

describe 'Submissions API', with: :api_v2 do
  let(:model_class) { Submission }
  let(:base_endpoint) { "/api/v2/#{resource_type}" }
  let(:resource_type) { model_class.name.demodulize.pluralize.underscore }

  it_behaves_like 'ApiKeyAuthenticatable'

  context 'with a list of resources' do
    let(:resource_count) { 5 }
    let!(:resources) { create_list(:submission, resource_count) }

    describe '#GET all resources' do
      before { api_get base_endpoint }

      it 'responds with a success http code' do
        expect(response).to have_http_status(:success)
      end

      it 'returns all the resources' do
        expect(json['data'].count).to eq(resource_count)
      end
    end

    describe '#filter' do
      let(:target_resource) { resources.sample }
      let(:target_id) { target_resource.id }

      describe 'by uuid' do
        before { api_get "#{base_endpoint}?filter[uuid]=#{target_resource.uuid}" }

        it_behaves_like 'it has filtered to a resource with target_id correctly'
      end
    end
  end

  context 'with a single resource' do
    let(:resource) { create(:submission, orders: create_list(:order, 2)) }

    describe '#GET resource by ID with default fields' do
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

        it 'responds with the correct created_at attribute value' do
          expect(json.dig('data', 'attributes', 'created_at')).to eq(resource.created_at.iso8601)
        end

        it 'responds with the correct name attribute value' do
          expect(json.dig('data', 'attributes', 'name')).to eq(resource.name)
        end

        it 'responds with the correct state attribute value' do
          expect(json.dig('data', 'attributes', 'state')).to eq(resource.state)
        end

        it 'responds with the correct updated_at attribute value' do
          expect(json.dig('data', 'attributes', 'updated_at')).to eq(resource.updated_at.iso8601)
        end

        it 'responds with the correct uuid attribute value' do
          expect(json.dig('data', 'attributes', 'uuid')).to eq(resource.uuid)
        end

        it 'does not include the used_tags attribute' do
          expect(json.dig('data', 'attributes', 'used_tags')).not_to be_present
        end

        it 'does not include the lanes_of_sequencing attribute' do
          expect(json.dig('data', 'attributes', 'lanes_of_sequencing')).not_to be_present
        end

        it 'does not include the order_uuids attribute' do
          expect(json.dig('data', 'attributes', 'order_uuids')).not_to be_present
        end

        it 'does not include the user_uuid attribute' do
          expect(json.dig('data', 'attributes', 'user_uuid')).not_to be_present
        end

        it 'does not include the orders relationship' do
          expect(json.dig('data', 'relationships', 'orders')).not_to be_present
        end

        it 'does not include the user relationship' do
          expect(json.dig('data', 'relationships', 'user')).not_to be_present
        end

        it 'does not include attributes for related resources' do
          expect(json['included']).not_to be_present
        end
      end
    end

    describe '#GET resource by ID with specific fields' do
      context 'with included relationships' do
        it_behaves_like 'a GET request including a has_many relationship', 'orders'
        it_behaves_like 'a GET request including a has_one relationship', 'user'
      end

      it 'can fetch the used_tags attribute' do
        api_get "#{base_endpoint}/#{resource.id}?fields[#{resource_type}]=used_tags"
        expect(json.dig('data', 'attributes', 'used_tags')).to eq(resource.used_tags)
      end

      it 'can fetch the lanes_of_sequencing attribute' do
        api_get "#{base_endpoint}/#{resource.id}?fields[#{resource_type}]=lanes_of_sequencing"
        expect(json.dig('data', 'attributes', 'lanes_of_sequencing')).to eq(resource.sequencing_requests.size)
      end

      it 'cannot fetch the writeonly order_uuids attribute' do
        api_get "#{base_endpoint}/#{resource.id}?fields[#{resource_type}]=order_uuids"
        expect(json.dig('data', 'attributes', 'order_uuids')).not_to be_present
      end

      it 'cannot fetch the writeonly user_uuid attribute' do
        api_get "#{base_endpoint}/#{resource.id}?fields[#{resource_type}]=user_uuid"
        expect(json.dig('data', 'attributes', 'user_uuid')).not_to be_present
      end
    end
  end

  describe '#PATCH a resource' do
    let(:resource_model) { create(:submission) }
    let(:payload) { { data: { id: resource_model.id, type: resource_type, attributes: {} } } }

    it 'finds no route for the method' do
      expect { api_patch "#{base_endpoint}/#{resource_model.id}", payload }.to raise_error(
        ActionController::RoutingError
      )
    end
  end

  describe '#POST a resource' do
    let(:orders) { create_list(:order, 2) }
    let(:user) { create(:user) }

    let(:orders_relationship) { { data: orders.map { |order| { id: order.id, type: 'orders' } } } }
    let(:user_relationship) { { data: { id: user.id, type: 'users' } } }

    context 'with a valid payload and no non-default fields' do
      shared_examples 'a valid request' do
        before { api_post base_endpoint, payload }

        it 'creates a new resource' do
          expect { api_post base_endpoint, payload }.to change(model_class, :count).by(1)
        end

        it 'responds with a success http code' do
          expect(response).to have_http_status(:success)
        end

        it 'returns the resource with the correct id' do
          new_record = model_class.last
          expect(json.dig('data', 'id')).to eq(new_record.id.to_s)
        end

        it 'returns the resource with the correct type' do
          expect(json.dig('data', 'type')).to eq(resource_type)
        end

        it 'responds with the correct created_at attribute value' do
          new_record = model_class.last
          expect(json.dig('data', 'attributes', 'created_at')).to eq(new_record.created_at.iso8601)
        end

        it 'responds with the correct name attribute value' do
          new_record = model_class.last
          expect(json.dig('data', 'attributes', 'name')).to eq(new_record.name)
        end

        it 'responds with the correct state attribute value' do
          new_record = model_class.last
          expect(json.dig('data', 'attributes', 'state')).to eq(new_record.state)
        end

        it 'responds with the correct updated_at attribute value' do
          new_record = model_class.last
          expect(json.dig('data', 'attributes', 'updated_at')).to eq(new_record.updated_at.iso8601)
        end

        it 'responds with the correct uuid attribute value' do
          new_record = model_class.last
          expect(json.dig('data', 'attributes', 'uuid')).to eq(new_record.uuid)
        end

        it 'associates the user with the model' do
          new_record = model_class.last
          expect(new_record.user).to eq(user)
        end

        it 'associates the orders with the model' do
          new_record = model_class.last
          expect(new_record.orders).to match_array(orders)
        end
      end

      describe 'passing user to the model' do
        context 'with all required attributes' do
          let(:orders) { nil }
          let(:payload) { { data: { type: resource_type, attributes: { user_uuid: user.uuid } } } }

          it_behaves_like 'a valid request'
        end

        context 'with all required relationships' do
          let(:orders) { nil }
          let(:payload) { { data: { type: resource_type, relationships: { user: user_relationship } } } }

          it_behaves_like 'a valid request'
        end

        context 'with user as both an attribute and a relationship' do
          let(:orders) { nil }
          let(:payload) do
            {
              data: {
                type: resource_type,
                attributes: {
                  user_uuid: create(:user).uuid
                },
                relationships: {
                  user: user_relationship
                }
              }
            }
          end

          it_behaves_like 'a valid request'
        end
      end

      describe 'passing orders to the model' do
        context 'with orders as an attribute' do
          let(:payload) do
            { data: { type: resource_type, attributes: { user_uuid: user.uuid, order_uuids: orders.map(&:uuid) } } }
          end

          it_behaves_like 'a valid request'
        end

        context 'with orders as a relationship' do
          let(:payload) do
            {
              data: {
                type: resource_type,
                attributes: {
                  user_uuid: user.uuid
                },
                relationships: {
                  orders: orders_relationship
                }
              }
            }
          end

          it_behaves_like 'a valid request'
        end

        context 'with order as both an attribute and a relationship' do
          let(:payload) do
            {
              data: {
                type: resource_type,
                attributes: {
                  user_uuid: user.uuid,
                  order_uuids: create_list(:order, 2).map(&:uuid)
                },
                relationships: {
                  orders: orders_relationship
                }
              }
            }
          end

          it_behaves_like 'a valid request'
        end
      end
    end

    describe 'using the and_submit attribute' do
      let(:and_submit) { nil }
      let(:payload) do
        {
          data: {
            type: resource_type,
            attributes: {
              and_submit:
            },
            relationships: {
              user: user_relationship,
              orders: orders_relationship
            }
          }
        }
      end

      before { api_post base_endpoint, payload }

      context 'when the and_submit attribute is true' do
        let(:and_submit) { true }

        it 'submits the submission' do
          expect(Submission.last.state).to eq('pending')
        end
      end

      context 'when the and_submit attribute is false' do
        let(:and_submit) { false }

        it 'does not submit the submission' do
          expect(Submission.last.state).to eq('building')
        end
      end

      context 'when the and_submit attribute is nil' do
        let(:and_submit) { nil }

        it 'does not submit the submission' do
          expect(Submission.last.state).to eq('building')
        end
      end
    end

    context 'with a read-only attribute in the payload' do
      context 'with created_at' do
        let(:disallowed_value) { 'created_at' }
        let(:payload) { { data: { type: resource_type, attributes: { created_at: '2024-11-19' } } } }

        it_behaves_like 'a POST request with a disallowed value'
      end

      context 'with state' do
        let(:disallowed_value) { 'state' }
        let(:payload) { { data: { type: resource_type, attributes: { state: 'pending' } } } }

        it_behaves_like 'a POST request with a disallowed value'
      end

      context 'with updated_at' do
        let(:disallowed_value) { 'updated_at' }
        let(:payload) { { data: { type: resource_type, attributes: { updated_at: '2024-11-19' } } } }

        it_behaves_like 'a POST request with a disallowed value'
      end

      context 'with uuid' do
        let(:disallowed_value) { 'uuid' }
        let(:payload) do
          { data: { type: resource_type, attributes: { uuid: '11111111-2222-3333-4444-555555666666' } } }
        end

        it_behaves_like 'a POST request with a disallowed value'
      end
    end
  end
end
