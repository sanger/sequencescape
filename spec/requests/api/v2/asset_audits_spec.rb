# frozen_string_literal: true

require 'rails_helper'
require './spec/requests/api/v2/shared_examples/api_key_authenticatable'

describe 'AssetAudits API', with: :api_v2 do
  let(:base_endpoint) { '/api/v2/asset_audits' }

  it_behaves_like 'ApiKeyAuthenticatable'

  context 'with multiple AssetAudits' do
    before { create_list(:asset_audit, 5) }

    it 'returns a list of asset audits' do
      api_get base_endpoint

      expect(response).to have_http_status(:success)
      expect(json['data'].length).to eq(5)
    end
  end

  context 'with an AssetAudit' do
    let(:resource_model) { create(:asset_audit) }
    let(:updated_resource_model) do
      resource_model.update(witnessed_by: 'new_witness_user')
      resource_model
    end

    let(:payload) do
      {
        'data' => {
          'id' => resource_model.id,
          'type' => 'asset_audits',
          'attributes' => {
            'witnessed_by' => updated_resource_model.witnessed_by,
          }
        }
      }
    end

    it 'returns an individual AssetAudit' do
      api_get "#{base_endpoint}/#{resource_model.id}"
      expect(response).to have_http_status(:success)
      expect(json.dig('data', 'type')).to eq('asset_audits')
      expect(json.dig('data','attributes', 'key')).to eq(resource_model.key)
      expect(json.dig('data', 'attributes','witnessed_by')).to eq(resource_model.witnessed_by)
    end

    it 'allows update of an AssetAudit' do
      api_patch "#{base_endpoint}/#{resource_model.id}", payload
      expect(response).to have_http_status(:success)
      expect(json.dig('data', 'type')).to eq('asset_audits')
      expect(json.dig('data', 'attributes', 'key')).to eq(resource_model.key )
      expect(json.dig('data', 'attributes', 'witnessed_by')).to eq(updated_resource_model.witnessed_by)
    end
  end

  describe '#post' do
    let(:labware) { create :labware }

    let(:payload) do
      {
        'data' => {
          'type' => 'asset_audits',
          'attributes' => {
            'key' => 'slf_receive_plates',
            'message' => 'This is a test message',
            'created_by' => 'test_user',
            'asset_uuid' => labware.uuid,
            'witnessed_by' => 'witness_user',
          },
        }
      }
    end

    it 'allows creation of an AssetAudit' do
      api_post base_endpoint, payload
      expect(response).to have_http_status(:success), response.body
      expect(json.dig('data', 'type')).to eq('asset_audits')
      expect(json.dig('data', 'attributes', 'key')).to eq('slf_receive_plates')
      expect(json.dig('data', 'attributes', 'asset_uuid')).to eq(labware.uuid)
    end
  end
end
