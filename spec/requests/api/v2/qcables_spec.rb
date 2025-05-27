# frozen_string_literal: true

require 'rails_helper'
require './spec/requests/api/v2/shared_examples/api_key_authenticatable'
require './spec/requests/api/v2/shared_examples/requests'

describe 'QcFiles API', tags: :lighthouse, with: :api_v2 do
  let(:model_class) { Qcable }
  let(:base_endpoint) { "/api/v2/#{resource_type}" }
  let(:resource_type) { model_class.name.demodulize.pluralize.underscore }

  it_behaves_like 'ApiKeyAuthenticatable'

  context 'with a list of resources' do
    let(:resource_count) { 5 }
    let!(:resources) { Array.new(resource_count) { create(:qcable_with_asset) } }

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

      describe 'by ean13 barcode' do
        before { api_get "#{base_endpoint}?filter[barcode]=#{target_resource.ean13_barcode}" }

        it_behaves_like 'it has filtered to a resource with target_id correctly'
      end

      describe 'by human barcode' do
        before { api_get "#{base_endpoint}?filter[barcode]=#{target_resource.human_barcode}" }

        it_behaves_like 'it has filtered to a resource with target_id correctly'
      end

      describe 'by machine barcode' do
        before { api_get "#{base_endpoint}?filter[barcode]=#{target_resource.machine_barcode}" }

        it_behaves_like 'it has filtered to a resource with target_id correctly'
      end

      describe 'by uuid' do
        before { api_get "#{base_endpoint}?filter[uuid]=#{target_resource.uuid}" }

        it_behaves_like 'it has filtered to a resource with target_id correctly'
      end
    end
  end

  context 'with a single resource' do
    describe '#GET resource by ID' do
      let(:resource) { create(:qcable_with_asset) }

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

        it 'responds with the correct labware_barcode attribute value' do
          barcode_hash = {
            'ean13_barcode' => resource.ean13_barcode,
            'machine_barcode' => resource.machine_barcode,
            'human_barcode' => resource.human_barcode
          }
          expect(json.dig('data', 'attributes', 'labware_barcode')).to eq(barcode_hash)
        end

        it 'responds with the correct state attribute value' do
          expect(json.dig('data', 'attributes', 'state')).to eq(resource.state)
        end

        it 'responds with the correct uuid attribute value' do
          expect(json.dig('data', 'attributes', 'uuid')).to eq(resource.uuid)
        end

        it 'returns a reference to the asset relationship' do
          expect(json.dig('data', 'relationships', 'asset')).to be_present
        end

        it 'returns a reference to the labware relationship' do
          expect(json.dig('data', 'relationships', 'labware')).to be_present
        end

        it 'returns a reference to the lot relationship' do
          expect(json.dig('data', 'relationships', 'lot')).to be_present
        end

        it 'does not include attributes for related resources' do
          expect(json['included']).not_to be_present
        end
      end

      context 'with included relationships' do
        it_behaves_like 'a GET request including a has_one relationship', 'asset'
        it_behaves_like 'a GET request including a has_one relationship', 'labware'
        it_behaves_like 'a GET request including a has_one relationship', 'lot'
      end
    end
  end

  describe '#PATCH a resource' do
    let(:resource) { create(:qcable_with_asset) }

    context 'with a valid payload' do
      let(:new_labware) { create(:full_plate) }

      context 'with non-deprecated relationships' do
        let(:new_lot) { create(:lot) }
        let(:payload) do
          {
            data: {
              id: resource.id,
              type: resource_type,
              relationships: {
                labware: {
                  data: {
                    type: 'labware',
                    id: new_labware.id
                  }
                },
                lot: {
                  data: {
                    type: 'lots',
                    id: new_lot.id
                  }
                }
              }
            }
          }
        end

        before { api_patch "#{base_endpoint}/#{resource.id}", payload }

        it 'updates the labware/asset on the resource' do
          expect(resource.reload.asset).to eq(new_labware)
        end

        it 'updates the lot on the resource' do
          expect(resource.reload.lot).to eq(new_lot)
        end
      end

      context 'with deprecated relationships' do
        let(:payload) do
          {
            data: {
              id: resource.id,
              type: resource_type,
              relationships: {
                asset: {
                  data: {
                    type: 'labware',
                    id: new_labware.id
                  }
                }
              }
            }
          }
        end

        before { api_patch "#{base_endpoint}/#{resource.id}", payload }

        it 'updates the labware/asset on the resource' do
          expect(resource.reload.asset).to eq(new_labware)
        end
      end
    end

    context 'with a read-only attribute in the payload' do
      context 'with labware_barcode' do
        let(:payload) do
          { data: { id: resource.id, type: resource_type, attributes: { labware_barcode: { human_barcode: '1-2' } } } }
        end

        it_behaves_like 'a PATCH request with a disallowed value', 'labware_barcode'
      end

      context 'with state' do
        let(:payload) { { data: { id: resource.id, type: resource_type, attributes: { state: 'pending' } } } }

        it_behaves_like 'a PATCH request with a disallowed value', 'state'
      end

      context 'with uuid' do
        let(:payload) { { data: { id: resource.id, type: resource_type, attributes: { uuid: 'new-uuid' } } } }

        it_behaves_like 'a PATCH request with a disallowed value', 'uuid'
      end
    end
  end

  describe '#POST a create request' do
    # This test is a bit weird, because for whatever reason, the resource is currently incomplete for Qcables. Qcables
    # validate the presence of a lot, asset, and qcable_creator, but the API doesn't allow you to set a qcable_creator.
    # So, we can't actually create a valid Qcable through the API.
    #
    # I don't know why this is the case - it seems like it was an oversight on this endpoint, but the endpoint is in use
    # already, so I don't want to modify it more than I have to.  It's quite likely that the endpoint should be
    # immutable, but it wasn't configured that way and I don't know what existing users may already be trying to do with
    # this endpoint, so I'm going to leave it alone.  For now, let's just test that the endpoint doesn't allow you to
    # create a Qcable and it can be adjusted in future if we need to be able to create them at that time.

    let(:labware) { create(:plate) }
    let(:lot) { create(:lot) }

    let(:labware_relationship) { { data: { id: labware.id, type: 'labware' } } }
    let(:lot_relationship) { { data: { id: lot.id, type: 'lots' } } }

    let(:base_attributes) { {} }
    let(:base_relationships) { { labware: labware_relationship, lot: lot_relationship } }

    context 'with a complete payload' do
      let(:payload) do
        { data: { type: resource_type, attributes: base_attributes, relationships: base_relationships } }
      end

      it 'fails with an unprocessable entity status' do
        api_post base_endpoint, payload
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it 'does not create a new resource' do
        expect { api_post base_endpoint, payload }.not_to change(model_class, :count)
      end
    end
  end

  context 'when DELETE request is unsuccessful' do
    let(:resource) { create(:qcable_with_asset) }

    it_behaves_like 'a DESTROY request for a v2 resource'
  end
end
