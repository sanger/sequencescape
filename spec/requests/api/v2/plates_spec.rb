# frozen_string_literal: true

require 'rails_helper'
require './spec/requests/api/v2/shared_examples/api_key_authenticatable'
require './spec/requests/api/v2/shared_examples/requests'

describe 'Plates API', tags: :lighthouse, with: :api_v2 do
  let(:model_class) { Plate }
  let(:base_endpoint) { "/api/v2/#{resource_type}" }
  let(:resource_type) { model_class.name.demodulize.pluralize.underscore }

  it_behaves_like 'ApiKeyAuthenticatable'

  context 'with a list of resources' do
    let(:resource_count) { 5 }

    before { create_list(:plate, resource_count) }

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
      let(:resource) { create(:plate, :with_submissions, :with_transfers_as_destination, well_count: 2) }

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

        it 'responds with the correct number_of_rows attribute value' do
          expect(json.dig('data', 'attributes', 'number_of_rows')).to eq(resource.height)
        end

        it 'responds with the correct number_of_columns attribute value' do
          expect(json.dig('data', 'attributes', 'number_of_columns')).to eq(resource.width)
        end

        it 'responds with the correct size attribute value' do
          expect(json.dig('data', 'attributes', 'size')).to eq(resource.size)
        end

        it 'responds with the correct pooling_metadata attribute value' do
          expect(json.dig('data', 'attributes', 'pooling_metadata')).to eq(resource.pools)
        end

        it 'returns a reference to the submission_pools relationship' do
          expect(json.dig('data', 'relationships', 'submission_pools')).to be_present
        end

        it 'returns a reference to the transfers_as_destination relationship' do
          expect(json.dig('data', 'relationships', 'transfers_as_destination')).to be_present
        end

        it 'does not include attributes for related resources' do
          expect(json['included']).not_to be_present
        end
      end

      context 'with included relationships' do
        it_behaves_like 'a GET request including a has_many relationship', 'submission_pools'
        it_behaves_like 'a GET request including a has_many relationship', 'transfers_as_destination'
        it_behaves_like 'a GET request including a has_many relationship', 'wells'
      end
    end
  end

  describe '#PATCH a resource' do
    let(:resource_model) { create(:plate) }
    let(:payload) { { data: { id: resource_model.id, type: resource_type, attributes: {} } } }

    it 'finds no route for the method' do
      expect { api_patch "#{base_endpoint}/#{resource_model.id}", payload }.to raise_error(
        ActionController::RoutingError
      )
    end
  end

  describe '#POST a create request' do
    let(:purpose) { create(:plate_purpose) }
    let(:wells) { create_list(:well, 2) }

    let(:purpose_relationship) { { data: { id: purpose.id, type: 'purposes' } } }
    let(:well_relationships) { { data: wells.map { |well| { id: well.id, type: 'wells' } } } }

    let(:base_attributes) { {} }
    let(:base_relationships) { { purpose: purpose_relationship, wells: well_relationships } }

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

        it 'responds with the correct number_of_rows attribute value' do
          new_record = model_class.last
          expect(json.dig('data', 'attributes', 'number_of_rows')).to eq(new_record.height)
        end

        it 'responds with the correct number_of_columns attribute value' do
          new_record = model_class.last
          expect(json.dig('data', 'attributes', 'number_of_columns')).to eq(new_record.width)
        end

        it 'responds with the correct size attribute value' do
          new_record = model_class.last
          expect(json.dig('data', 'attributes', 'size')).to eq(new_record.size)
        end

        it 'responds with the correct pooling_metadata attribute value' do
          new_record = model_class.last
          expect(json.dig('data', 'attributes', 'pooling_metadata')).to eq(new_record.pools)
        end

        it 'returns a reference to the submission_pools relationship' do
          expect(json.dig('data', 'relationships', 'submission_pools')).to be_present
        end

        it 'returns a reference to the transfers_as_destination relationship' do
          expect(json.dig('data', 'relationships', 'transfers_as_destination')).to be_present
        end

        it 'associates the purpose with the new record' do
          new_record = model_class.last
          expect(new_record.purpose).to eq(purpose)
        end

        it 'associates the wells with the new record' do
          new_record = model_class.last
          expect(new_record.wells).to eq(wells)
        end
      end

      context 'with all required relationships' do
        let(:payload) do
          { data: { type: resource_type, attributes: base_attributes, relationships: base_relationships } }
        end

        it_behaves_like 'a valid request'
      end

      context 'with optional size attribute' do
        let(:payload) do
          {
            data: {
              type: resource_type,
              attributes: base_attributes.merge(size: 384),
              relationships: base_relationships
            }
          }
        end

        it_behaves_like 'a valid request'
      end
    end

    context 'with a read-only attribute in the payload' do
      context 'with number_of_rows' do
        let(:disallowed_value) { 'number_of_rows' }
        let(:payload) { { data: { type: resource_type, attributes: { number_of_rows: 5 } } } }

        it_behaves_like 'a POST request with a disallowed value'
      end

      context 'with number_of_columns' do
        let(:disallowed_value) { 'number_of_columns' }
        let(:payload) { { data: { type: resource_type, attributes: { number_of_columns: 10 } } } }

        it_behaves_like 'a POST request with a disallowed value'
      end

      context 'with pooling_metadata' do
        let(:disallowed_value) { 'pooling_metadata' }
        let(:payload) { { data: { type: resource_type, attributes: { pooling_metadata: {} } } } }

        it_behaves_like 'a POST request with a disallowed value'
      end
    end

    context 'with a read-only relationship in the payload' do
      context 'with submission_pools' do
        let(:disallowed_value) { 'submission_pools' }
        let(:payload) do
          {
            data: {
              type: resource_type,
              relationships: {
                submission_pools: {
                  data: [{ id: '1', type: 'submission_pools' }]
                }
              }
            }
          }
        end

        it_behaves_like 'a POST request with a disallowed value'
      end

      context 'with transfers_as_destination' do
        let(:disallowed_value) { 'transfers_as_destination' }
        let(:payload) do
          {
            data: {
              type: resource_type,
              relationships: {
                transfers_as_destination: {
                  data: [{ id: '1', type: 'transfers' }]
                }
              }
            }
          }
        end

        it_behaves_like 'a POST request with a disallowed value'
      end
    end
  end

  context 'when DELETE request is unsuccessful' do
    let(:resource) { create(:plate) }

    it_behaves_like 'a DESTROY request for a v2 resource'
  end
end
