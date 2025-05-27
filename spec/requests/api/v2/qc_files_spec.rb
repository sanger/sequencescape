# frozen_string_literal: true

require 'rails_helper'
require './spec/requests/api/v2/shared_examples/api_key_authenticatable'
require './spec/requests/api/v2/shared_examples/requests'

describe 'QcFiles API', tags: :lighthouse, with: :api_v2 do
  let(:model_class) { QcFile }
  let(:base_endpoint) { "/api/v2/#{resource_type}" }
  let(:resource_type) { model_class.name.demodulize.pluralize.underscore }

  it_behaves_like 'ApiKeyAuthenticatable'

  context 'with a list of resources' do
    let(:resource_count) { 5 }
    let!(:resources) { create_list(:qc_file, resource_count) }

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
    describe '#GET resource by ID' do
      let(:resource) { create(:qc_file) }

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

        it 'responds with the correct content_type attribute value' do
          expect(json.dig('data', 'attributes', 'content_type')).to eq(resource.content_type)
        end

        it 'responds with the correct contents attribute value' do
          expect(json.dig('data', 'attributes', 'contents')).to eq(resource.current_data)
        end

        it 'responds with the correct created_at attribute value' do
          expect(json.dig('data', 'attributes', 'created_at')).to eq(resource.created_at.iso8601)
        end

        it 'responds with the correct filename attribute value' do
          expect(json.dig('data', 'attributes', 'filename')).to eq(resource.filename)
        end

        it 'responds with the correct size attribute value' do
          expect(json.dig('data', 'attributes', 'size')).to eq(resource.size)
        end

        it 'responds with the correct uuid attribute value' do
          expect(json.dig('data', 'attributes', 'uuid')).to eq(resource.uuid)
        end

        it 'returns a reference to the labware relationship' do
          expect(json.dig('data', 'relationships', 'labware')).to be_present
        end

        it 'does not include attributes for related resources' do
          expect(json['included']).not_to be_present
        end
      end

      context 'with included relationships' do
        it_behaves_like 'a GET request including a has_one relationship', 'labware'
      end
    end
  end

  describe '#PATCH a resource' do
    let(:resource_model) { create(:qc_file) }
    let(:payload) { { data: { id: resource_model.id, type: resource_type, attributes: {} } } }

    it 'finds no route for the method' do
      expect { api_patch "#{base_endpoint}/#{resource_model.id}", payload }.to raise_error(
        ActionController::RoutingError
      )
    end
  end

  describe '#POST a create request' do
    let(:labware) { create(:plate) }

    let(:labware_relationship) { { data: { id: labware.id, type: 'labware' } } }

    let(:base_attributes) { { contents: "A1,A2,A3\n1,2,3\n4,5,6\n", filename: 'test_file.csv' } }
    let(:base_relationships) { { labware: labware_relationship } }

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

        it 'responds with the correct content_type attribute value' do
          new_record = model_class.last
          expect(json.dig('data', 'attributes', 'content_type')).to eq(new_record.content_type)
        end

        it 'responds with the correct contents attribute value' do
          new_record = model_class.last
          expect(json.dig('data', 'attributes', 'contents')).to eq(new_record.current_data)
        end

        it 'responds with the correct created_at attribute value' do
          new_record = model_class.last
          expect(json.dig('data', 'attributes', 'created_at')).to eq(new_record.created_at.iso8601)
        end

        it 'responds with the correct filename attribute value' do
          new_record = model_class.last
          expect(json.dig('data', 'attributes', 'filename')).to eq(new_record.filename)
        end

        it 'responds with the correct size attribute value' do
          new_record = model_class.last
          expect(json.dig('data', 'attributes', 'size')).to eq(new_record.size)
        end

        it 'returns a reference to the labware relationship' do
          expect(json.dig('data', 'relationships', 'labware')).to be_present
        end

        it 'associates the labware with the new record' do
          new_record = model_class.last
          expect(new_record.asset).to eq(labware)
        end
      end

      context 'with all required attributes and relationships' do
        let(:payload) do
          { data: { type: resource_type, attributes: base_attributes, relationships: base_relationships } }
        end

        it_behaves_like 'a valid request'
      end
    end

    context 'with a read-only attribute in the payload' do
      context 'with content_type' do
        let(:disallowed_value) { 'content_type' }
        let(:payload) { { data: { type: resource_type, attributes: { content_type: 'amazing/content' } } } }

        it_behaves_like 'a POST request with a disallowed value'
      end

      context 'with created_at' do
        let(:disallowed_value) { 'created_at' }
        let(:payload) { { data: { type: resource_type, attributes: { created_at: '2024-11-19' } } } }

        it_behaves_like 'a POST request with a disallowed value'
      end

      context 'with size' do
        let(:disallowed_value) { 'size' }
        let(:payload) { { data: { type: resource_type, attributes: { size: 123 } } } }

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

    context 'with a missing required attribute' do
      context 'without contents' do
        let(:payload) do
          {
            data: {
              type: resource_type,
              attributes: base_attributes.merge({ contents: nil }),
              relationships: base_relationships
            }
          }
        end

        it_behaves_like 'a POST request with a missing parameter', 'contents'
      end

      context 'without filename' do
        let(:payload) do
          {
            data: {
              type: resource_type,
              attributes: base_attributes.merge({ filename: nil }),
              relationships: base_relationships
            }
          }
        end

        it_behaves_like 'a POST request with a missing parameter', 'filename'
      end
    end

    context 'with a missing required relationship' do
      context 'without labware' do
        # Not an ideal response, but this is how the model validates.
        let(:error_detail_message) { "asset - can't be blank" }

        let(:payload) do
          {
            data: {
              type: resource_type,
              attributes: base_attributes,
              relationships: base_relationships.merge({ labware: nil })
            }
          }
        end

        it_behaves_like 'an unprocessable POST request with a specific error'
      end
    end
  end

  context 'when DELETE request is unsuccessful' do
    let(:resource) { create(:qc_file) }

    it_behaves_like 'a DESTROY request for a v2 resource'
  end
end
