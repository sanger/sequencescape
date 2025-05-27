# frozen_string_literal: true

require 'rails_helper'
require './spec/requests/api/v2/shared_examples/api_key_authenticatable'
require './spec/requests/api/v2/shared_examples/requests'

describe 'PickLists API', :pick_list, with: :api_v2 do
  let(:base_endpoint) { '/api/v2/pick_lists' }

  it_behaves_like 'ApiKeyAuthenticatable'

  context 'with multiple PickLists' do
    before { create_list(:pick_list, 5) }

    it 'sends a list of pick_lists' do
      api_get base_endpoint

      # test for the 200 status-code
      expect(response).to have_http_status(:success)

      # check to make sure the right amount of messages are returned
      expect(json['data'].length).to eq(5)
    end

    # Check filters, ESPECIALLY if they aren't simple attribute filters
  end

  context 'with a PickList' do
    let(:resource_model) { create(:pick_list) }
    let(:payload) do
      {
        'data' => {
          'id' => resource_model.id,
          'type' => 'pick_lists',
          'attributes' => {
            # Set new attributes
          }
        }
      }
    end

    it 'sends an individual PickList' do
      api_get "#{base_endpoint}/#{resource_model.id}"
      expect(response).to have_http_status(:success)
      expect(json.dig('data', 'type')).to eq('pick_lists')
    end

    # Remove if immutable
    it 'allows update of a PickList' do
      api_patch "#{base_endpoint}/#{resource_model.id}", payload
      expect(response).to have_http_status(:success)
      expect(json.dig('data', 'type')).to eq('pick_lists')
      # Double check at least one of the attributes
      # eg. expect(json.dig('data', 'attributes', 'state')).to eq('started')
    end
  end

  describe 'POST' do
    before do
      rt = create(:cherrypick_request_type, key: 'cherrypick')
      create(:cherrypick_pipeline, request_type: rt)
    end

    context 'with pick_attributes' do
      let(:wells) { create_list(:untagged_well, 2) }

      let(:payload) do
        {
          'data' => {
            'type' => 'pick_lists',
            'attributes' => {
              'asynchronous' => true,
              'pick_attributes' => wells.map { |w| { source_receptacle_id: w.id } }
            }
          }
        }
      end

      it 'allows creation of a PickList', :aggregate_failures do
        api_post base_endpoint, payload

        expect(response).to have_http_status(:created)
        expect(json.dig('data', 'type')).to eq('pick_lists')
        expect(json.dig('data', 'attributes', 'state')).to eq('pending')
      end
    end

    context 'with labware_pick_attributes' do
      let(:plate_1) { create(:plate_with_untagged_wells, well_count: 1) }
      let(:plate_2) { create(:plate_with_untagged_wells, well_count: 2) }

      let(:payload) do
        {
          'data' => {
            'type' => 'pick_lists',
            'attributes' => {
              'asynchronous' => true,
              'labware_pick_attributes' => [
                { source_labware_id: plate_1.id },
                { source_labware_barcode: plate_2.machine_barcode }
              ]
            }
          }
        }
      end

      it 'allows creation of a PickList', :aggregate_failures do
        api_post base_endpoint, payload

        expect(response).to have_http_status(:created)
        expect(json.dig('data', 'type')).to eq('pick_lists')
        expect(json.dig('data', 'attributes', 'state')).to eq('pending')
        expect(json.dig('data', 'attributes', 'pick_attributes').length).to eq(3)
      end
    end
  end

  context 'when DELETE request is unsuccessful' do
    let(:resource) { create(:pick_list) }

    it_behaves_like 'a DESTROY request for a v2 resource'
  end
end
