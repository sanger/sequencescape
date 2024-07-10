# frozen_string_literal: true

require 'rails_helper'
require './spec/requests/api/v2/shared_examples/api_key_authenticatable'

describe 'PlatePurposes API', with: :api_v2 do
  let(:base_endpoint) { '/api/v2/plate_purposes' }

  it_behaves_like 'ApiKeyAuthenticatable'

  context 'with multiple PlatePurposes' do
    before { create_list(:plate_purpose, 5) }

    it 'returns a list of plate purposes' do
      api_get base_endpoint

      expect(response).to have_http_status(:success)
      expect(json['data'].length).to eq(5)
    end
  end

  context 'with a PlatePurpose' do
    let(:resource_model) { create(:plate_purpose) }
    let(:updated_size) { 48 }

    let(:payload) do
      {
        'data' => {
          'id' => resource_model.id,
          'type' => 'plate_purposes',
          'attributes' => {
            'size' => updated_size
          }
        }
      }
    end

    it 'returns an individual PlatePurpose' do
      api_get "#{base_endpoint}/#{resource_model.id}"
      expect(response).to have_http_status(:success)
      expect(json.dig('data', 'type')).to eq('plate_purposes')
      expect(json.dig('data', 'attributes', 'cherrypickable_target')).to eq(resource_model.cherrypickable_target)
      expect(json.dig('data', 'attributes', 'size')).to eq(resource_model.size)
    end

    it 'does not allow update of a PlatePurpose' do
      api_patch "#{base_endpoint}/#{resource_model.id}", payload
      expect(response).to have_http_status(:bad_request)
      expect(json.dig('errors', 0, 'detail')).to eq('size is not allowed.')
    end
  end

  describe '#post' do
    let(:asset_shape) { create :asset_shape }

    let(:payload) do
      {
        'data' => {
          'type' => 'plate_purposes',
          'attributes' => {
            'name' => 'My Plate Purpose',
            'stock_plate' => true,
            'cherrypickable_target' => false,
            'size' => 384,
            'asset_shape' => asset_shape.name
          }
        }
      }
    end

    it 'allows creation of a PlatePurpose' do
      api_post base_endpoint, payload
      expect(response).to have_http_status(:success), response.body
      expect(json.dig('data', 'type')).to eq('plate_purposes')
      expect(json.dig('data', 'attributes', 'name')).to eq('My Plate Purpose')
      expect(json.dig('data', 'attributes', 'size')).to eq(384)
      expect(json.dig('data', 'attributes', 'asset_shape')).to eq(asset_shape.name)
    end
  end
end
