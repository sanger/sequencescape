# frozen_string_literal: true

require 'rails_helper'
require './spec/requests/api/v2/shared_examples/api_key_authenticatable'

describe 'VolumeUpdate API', with: :api_v2 do
  let(:base_endpoint) { '/api/v2/volume_updates' }

  it_behaves_like 'ApiKeyAuthenticatable'

  context 'with multiple VolumeUpdates' do
    before { create_list(:volume_update, 5) }

    it 'returns a list of volume updates' do
      api_get base_endpoint

      expect(response).to have_http_status(:success)
      expect(json['data'].length).to eq(5)
    end
  end

  context 'with a VolumeUpdate' do
    let(:resource_model) { create(:volume_update) }
    let(:updated_volume_change) { 10.0 }

    let(:payload) do
      {
        'data' => {
          'id' => resource_model.id,
          'type' => 'volume_updates',
          'attributes' => {
            'volume_change' => updated_volume_change
          }
        }
      }
    end

    it 'returns an individual VolumeUpdate' do
      api_get "#{base_endpoint}/#{resource_model.id}"
      expect(response).to have_http_status(:success)
      expect(json.dig('data', 'type')).to eq('volume_updates')
      expect(json.dig('data', 'attributes', 'volume_change')).to eq(resource_model.volume_change)
    end

    it 'does not allow update of a VolumeUpdate' do
      api_patch "#{base_endpoint}/#{resource_model.id}", payload
      expect(response).to have_http_status(:bad_request)
      expect(json.dig('errors', 0, 'detail')).to eq('volume_change is not allowed.')
    end
  end

  describe '#post' do
    let(:plate) { create(:plate) } # Only works for plates as update_volume is not set for all labware

    let(:payload) do
      {
        'data' => {
          'type' => 'volume_updates',
          'attributes' => {
            'volume_change' => 5.0,
            'created_by' => 'test_user',
            'target_uuid' => plate.uuid
          }
        }
      }
    end

    it 'allows creation of a VolumeUpdate' do
      api_post base_endpoint, payload
      expect(response).to have_http_status(:success), response.body
      expect(json.dig('data', 'type')).to eq('volume_updates')
      expect(json.dig('data', 'attributes', 'created_by')).to eq('test_user')
      expect(json.dig('data', 'attributes', 'target_uuid')).to eq(plate.uuid)
      expect(json.dig('data', 'attributes', 'volume_change')).to eq(5.0)
    end
  end
end
