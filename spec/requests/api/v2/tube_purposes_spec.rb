# frozen_string_literal: true

require 'rails_helper'
require './spec/requests/api/v2/shared_examples/api_key_authenticatable'

describe 'Tube Purposes API', with: :api_v2 do
  let(:base_endpoint) { '/api/v2/tube_purposes' }

  it_behaves_like 'ApiKeyAuthenticatable'

  describe '#get all Tube Purposes' do
    before { create_list(:tube_purpose, 5) }

    it 'returns the list of Tube Purposes' do
      api_get base_endpoint

      expect(response).to have_http_status(:success)
      expect(json['data'].length).to eq(5)
    end
  end

  describe '#get a specific Tube Purpose' do
    let(:resource_model) { create(:tube_purpose) }

    it 'returns the template' do
      api_get "#{base_endpoint}/#{resource_model.id}"
      expect(response).to have_http_status(:success)
      expect(json.dig('data', 'type')).to eq('tube_purposes')
      expect(json.dig('data', 'attributes', 'name')).to eq(resource_model.name)
      expect(json.dig('data', 'attributes', 'purpose_type')).to eq(resource_model.type)
      expect(json.dig('data', 'attributes', 'target_type')).to eq(resource_model.target_type)
    end
  end

  describe '#patch a specific Tube Purpose' do
    let(:resource_model) { create(:tube_purpose) }

    context 'patching the name' do
      let(:updated_name) { 'Updated Name' }
      let(:payload) do
        {
          'data' => {
            'id' => resource_model.id,
            'type' => 'tube_purposes',
            'attributes' => {
              'name' => updated_name
            }
          }
        }
      end

      it 'patches correctly' do
        api_patch "#{base_endpoint}/#{resource_model.id}", payload
        expect(response).to have_http_status(:success)
        expect(json.dig('data', 'type')).to eq('tube_purposes')
        expect(json.dig('data', 'attributes', 'name')).to eq(updated_name)
        expect(json.dig('data', 'attributes', 'purpose_type')).to eq(resource_model.type)
        expect(json.dig('data', 'attributes', 'target_type')).to eq(resource_model.target_type)
      end
    end

    context 'patching the purpose_type' do
      let(:updated_purpose_type) { 'Updated Purpose Type' }
      let(:payload) do
        {
          'data' => {
            'id' => resource_model.id,
            'type' => 'tube_purposes',
            'attributes' => {
              'purpose_type' => updated_purpose_type
            }
          }
        }
      end

      it 'patches correctly' do
        api_patch "#{base_endpoint}/#{resource_model.id}", payload
        expect(response).to have_http_status(:success)
        expect(json.dig('data', 'type')).to eq('tube_purposes')
        expect(json.dig('data', 'attributes', 'name')).to eq(resource_model.name)
        expect(json.dig('data', 'attributes', 'purpose_type')).to eq(updated_purpose_type)
        expect(json.dig('data', 'attributes', 'target_type')).to eq(resource_model.target_type)
      end
    end

    context 'patching the target_type' do
      let(:updated_target_type) { 'SampleTube' }
      let(:payload) do
        {
          'data' => {
            'id' => resource_model.id,
            'type' => 'tube_purposes',
            'attributes' => {
              'target_type' => updated_target_type
            }
          }
        }
      end

      it 'patches correctly' do
        api_patch "#{base_endpoint}/#{resource_model.id}", payload
        expect(response).to have_http_status(:success)
        expect(json.dig('data', 'type')).to eq('tube_purposes')
        expect(json.dig('data', 'attributes', 'name')).to eq(resource_model.name)
        expect(json.dig('data', 'attributes', 'purpose_type')).to eq(resource_model.type)
        expect(json.dig('data', 'attributes', 'target_type')).to eq(updated_target_type)
      end
    end
  end

  describe '#post a new Tube Purpose' do
    context 'with a valid payload' do
      let(:payload) do
        {
          'data' => {
            'type' => 'tube_purposes',
            'attributes' => {
              'name' => 'New Name',
              'purpose_type' => 'Test Purpose Type',
              'target_type' => 'MultiplexedLibraryTube'
            }
          }
        }
      end

      it 'creates the Tube Purpose' do
        api_post base_endpoint, payload
        expect(response).to have_http_status(:created)
        expect(json.dig('data', 'type')).to eq('tube_purposes')
        expect(json.dig('data', 'attributes', 'name')).to eq('New Name')
        expect(json.dig('data', 'attributes', 'purpose_type')).to eq('Test Purpose Type')
        expect(json.dig('data', 'attributes', 'target_type')).to eq('MultiplexedLibraryTube')
      end
    end

    context 'with an invalid payload (missing target_type)' do
      let(:payload) do
        {
          'data' => {
            'type' => 'tube_purposes',
            'attributes' => {
              'name' => 'New Name',
              'purpose_type' => 'Test Purpose Type'
            }
          }
        }
      end

      it 'responds with 422 unprocessable entity' do
        api_post base_endpoint, payload
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end
end
