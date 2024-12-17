# frozen_string_literal: true

require 'rails_helper'
require './spec/requests/api/v2/shared_examples/api_key_authenticatable'
require './spec/requests/api/v2/shared_examples/requests'

# rubocop:disable RSpec/MultipleExpectations
describe 'Specific Tube Rack Creations API', with: :api_v2 do
  let(:model_class) { SpecificTubeRackCreation }
  let(:resource_type) { model_class.name.demodulize.pluralize.underscore }
  let(:base_endpoint) { "/api/v2/#{resource_type}" }
  let(:user) { create(:user) }

  let(:basic_tube_rack_attributes) do
    [
      {
        tube_rack_name: 'Tube Rack 1',
        tube_rack_barcode: 'TR00000001',
        tube_rack_purpose_uuid: tube_rack_purpose.uuid,
        racked_tubes: [
          {
            tube_barcode: 'ST00000001',
            tube_name: 'SEQ:NT1A:A1',
            tube_purpose_uuid: tube_purpose.uuid,
            tube_position: 'A1',
            parent_uuids: [parent_plate.uuid]
          }
        ]
      }
    ]
  end
  let(:tube_purpose) { create(:tube_purpose, name: 'example-tube-purpose-uuid') }
  let(:tube_rack_purpose) { create(:tube_rack_purpose, name: 'example-tube-rack-purpose-uuid') }
  let(:parent_plate) { create(:plate, well_count: 1) }

  it_behaves_like 'ApiKeyAuthenticatable'

  context 'with a list of resources' do
    before { create(:specific_tube_rack_creation, tube_rack_attributes: basic_tube_rack_attributes) }

    describe '#GET all resources' do
      before { api_get base_endpoint }

      it 'responds with a success http code' do
        expect(response).to have_http_status(:success)
      end

      it 'returns all the resources' do
        expect(json['data'].length).to eq(1)
      end
    end
  end

  describe '#GET with a single resource' do
    let(:parents) { [create(:plate)] }
    let(:resource) { create(:specific_tube_rack_creation, tube_rack_attributes: basic_tube_rack_attributes) }

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
        expect(json.dig('data', 'attributes', 'parent_uuids')).not_to be_present
        expect(json.dig('data', 'attributes', 'tube_rack_attributes')).not_to be_present
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
      # it_behaves_like 'a GET request including a has_many relationship', 'children'
      it_behaves_like 'a GET request including a has_many relationship', 'parents'
      it_behaves_like 'a GET request including a has_one relationship', 'user'
    end
  end

  describe '#PATCH a resource' do
    let(:resource_model) { create(:specific_tube_rack_creation, tube_rack_attributes: basic_tube_rack_attributes) }
    let(:payload) { { data: { id: resource_model.id, type: resource_type, attributes: {} } } }

    it 'finds no route for the method' do
      expect { api_patch "#{base_endpoint}/#{resource_model.id}", payload }.to raise_error(
        ActionController::RoutingError
      )
    end
  end

  describe '#POST a create request' do
    let(:parents) { [create(:plate)] }
    let(:user) { create(:user) }

    let(:base_attributes) { { tube_rack_attributes: basic_tube_rack_attributes } }

    let(:parents_relationship) { { data: parents.map { |p| { id: p.id, type: 'labware' } } } }
    let(:user_relationship) { { data: { id: user.id, type: 'users' } } }

    # expected tube rack purposes from the attributes
    let(:expected_child_purposes) do
      basic_tube_rack_attributes.map { |attr| TubeRack::Purpose.with_uuid(attr[:tube_rack_purpose_uuid]).first }
    end

    context 'with a valid payload' do
      shared_examples 'a valid request' do
        it 'creates a new resource' do
          expect { api_post base_endpoint, payload }.to change(model_class, :count).by(1)
        end

        context 'when a resource has been made' do
          before { api_post base_endpoint, payload }

          it 'responds with success' do
            expect(response).to have_http_status(:success)
          end

          it 'responds with the correct attributes' do
            new_record = model_class.last

            expect(json.dig('data', 'type')).to eq(resource_type)
            expect(json.dig('data', 'attributes', 'uuid')).to eq(new_record.uuid)
          end

          it 'excludes unfetchable attributes' do
            expect(json.dig('data', 'attributes', 'parent_uuids')).not_to be_present
            expect(json.dig('data', 'attributes', 'tube_rack_attributes')).not_to be_present
          end

          it 'returns references to related resources' do
            expect(json.dig('data', 'relationships', 'parents')).to be_present
            expect(json.dig('data', 'relationships', 'user')).to be_present
          end

          it 'applies the attributes to the new record' do
            new_record = model_class.last

            # Note that the tube_rack_attributes from the queried record will not match the submitted values,
            # but it will consist of empty hashes equalling the number of child purposes, as defined in the model.
            expect(new_record.tube_rack_attributes).to eq(Array.new(expected_child_purposes.length, {}))
          end

          it 'applies the relationships to the new record' do
            new_record = model_class.last

            expect(new_record.child_purposes).to eq(expected_child_purposes)
            expect(new_record.parents).to eq(parents)
            expect(new_record.user).to eq(user)
          end

          it 'generated children with valid attributes' do
            new_record = model_class.last

            expect(new_record.children.length).to eq(1)
            expect(new_record.children.map(&:name)).to eq(['Tube Rack 1'])

            expect(new_record.children.map(&:purpose)).to eq(expected_child_purposes)
          end
        end
      end

      context 'with complete attributes' do
        let(:payload) do
          {
            data: {
              type: resource_type,
              attributes: base_attributes.merge({ parent_uuids: parents.map(&:uuid), user_uuid: user.uuid })
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
end

# rubocop:enable RSpec/MultipleExpectations
