# frozen_string_literal: true

require 'rails_helper'
require './spec/requests/api/v2/shared_examples/api_key_authenticatable'

# rubocop:disable RSpec/ExampleLength, RSpec/MultipleExpectations
describe 'Tube Rack Purposes API', with: :api_v2 do
  let(:base_endpoint) { '/api/v2/tube_rack_purposes' }

  it_behaves_like 'ApiKeyAuthenticatable'

  describe '#get all Tube Rack Purposes' do
    before { create_list(:tube_rack_purpose, 5) }

    it 'returns a successful response' do
      api_get base_endpoint

      expect(response).to have_http_status(:success)
    end

    it 'returns the list of Tube Rack Purposes' do
      api_get base_endpoint

      expect(json['data'].length).to eq(5)
    end
  end

  describe '#get a specific Tube Rack Purpose' do
    let(:resource_model) { create(:tube_rack_purpose) }

    it 'returns the template' do
      api_get "#{base_endpoint}/#{resource_model.id}"
      expect(response).to have_http_status(:success)
      expect(json.dig('data', 'type')).to eq('tube_rack_purposes')
      expect(json.dig('data', 'attributes', 'name')).to eq(resource_model.name)
      expect(json.dig('data', 'attributes', 'purpose_type')).to eq(resource_model.type)
      expect(json.dig('data', 'attributes', 'size')).to eq(resource_model.size)
      expect(json.dig('data', 'attributes', 'target_type')).to eq(resource_model.target_type)
      expect(json.dig('data', 'attributes', 'uuid')).to eq(resource_model.uuid)
    end
  end

  describe '#patch a specific Tube Rack Purpose' do
    let(:resource_model) { create(:tube_rack_purpose) }

    context 'when patching the name' do
      let(:updated_name) { 'Updated Name' }
      let(:payload) do
        {
          'data' => {
            'id' => resource_model.id,
            'type' => 'tube_rack_purposes',
            'attributes' => {
              'name' => updated_name
            }
          }
        }
      end

      it 'patches correctly' do
        api_patch "#{base_endpoint}/#{resource_model.id}", payload
        expect(response).to have_http_status(:success)
        expect(json.dig('data', 'type')).to eq('tube_rack_purposes')
        expect(json.dig('data', 'attributes', 'name')).to eq(updated_name)
        expect(json.dig('data', 'attributes', 'size')).to eq(resource_model.size)
        expect(json.dig('data', 'attributes', 'purpose_type')).to eq(resource_model.type)
        expect(json.dig('data', 'attributes', 'target_type')).to eq(resource_model.target_type)
        expect(json.dig('data', 'attributes', 'uuid')).to eq(resource_model.uuid)
      end
    end

    context 'when patching the purpose_type' do
      let(:updated_purpose_type) { 'Updated Purpose Type' }
      let(:payload) do
        {
          'data' => {
            'id' => resource_model.id,
            'type' => 'tube_rack_purposes',
            'attributes' => {
              'purpose_type' => updated_purpose_type
            }
          }
        }
      end

      it 'patches correctly' do
        api_patch "#{base_endpoint}/#{resource_model.id}", payload
        expect(response).to have_http_status(:success)
        expect(json.dig('data', 'type')).to eq('tube_rack_purposes')
        expect(json.dig('data', 'attributes', 'name')).to eq(resource_model.name)
        expect(json.dig('data', 'attributes', 'size')).to eq(resource_model.size)
        expect(json.dig('data', 'attributes', 'purpose_type')).to eq(updated_purpose_type)
        expect(json.dig('data', 'attributes', 'target_type')).to eq(resource_model.target_type)
        expect(json.dig('data', 'attributes', 'uuid')).to eq(resource_model.uuid)
      end
    end

    context 'when patching the target_type' do
      let(:updated_target_type) { 'SampleTubeRack' }
      let(:payload) do
        {
          'data' => {
            'id' => resource_model.id,
            'type' => 'tube_rack_purposes',
            'attributes' => {
              'target_type' => updated_target_type
            }
          }
        }
      end

      it 'patches correctly' do
        api_patch "#{base_endpoint}/#{resource_model.id}", payload
        expect(response).to have_http_status(:success)
        expect(json.dig('data', 'type')).to eq('tube_rack_purposes')
        expect(json.dig('data', 'attributes', 'name')).to eq(resource_model.name)
        expect(json.dig('data', 'attributes', 'size')).to eq(resource_model.size)
        expect(json.dig('data', 'attributes', 'purpose_type')).to eq(resource_model.type)
        expect(json.dig('data', 'attributes', 'target_type')).to eq(updated_target_type)
        expect(json.dig('data', 'attributes', 'uuid')).to eq(resource_model.uuid)
      end
    end

    context 'when patching the uuid' do
      let(:updated_uuid) { 'new-uuid' }
      let(:payload) do
        {
          'data' => {
            'id' => resource_model.id,
            'type' => 'tube_rack_purposes',
            'attributes' => {
              'uuid' => updated_uuid
            }
          }
        }
      end

      it 'responds with 400 bad request, because uuid is read-only' do
        api_patch "#{base_endpoint}/#{resource_model.id}", payload
        expect(response).to have_http_status(:bad_request)
      end
    end
  end

  describe '#post a new Tube Rack Purpose' do
    context 'with a valid payload' do
      let(:payload) do
        {
          'data' => {
            'type' => 'tube_rack_purposes',
            'attributes' => {
              'name' => 'New Name',
              'purpose_type' => 'Test Purpose Type',
              'target_type' => 'TubeRack'
            }
          }
        }
      end

      it 'creates the Tube Rack Purpose' do
        api_post base_endpoint, payload
        expect(response).to have_http_status(:created)
        expect(json.dig('data', 'type')).to eq('tube_rack_purposes')
        expect(json.dig('data', 'attributes', 'name')).to eq('New Name')
        expect(json.dig('data', 'attributes', 'purpose_type')).to eq('Test Purpose Type')
        expect(json.dig('data', 'attributes', 'target_type')).to eq('TubeRack')
      end
    end

    context 'with an invalid payload (missing target_type)' do
      let(:payload) do
        {
          'data' => {
            'type' => 'tube_rack_purposes',
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

    context 'with an invalid payload (includes uuid)' do
      let(:payload) do
        {
          'data' => {
            'type' => 'tube_rack_purposes',
            'attributes' => {
              'name' => 'New Name',
              'purpose_type' => 'Test Purpose Type',
              'target_type' => 'TubeRack',
              'uuid' => 'new-uuid'
            }
          }
        }
      end

      it 'responds with 400 bad request, because uuid is read-only' do
        api_post base_endpoint, payload
        expect(response).to have_http_status(:bad_request)
      end
    end
  end
end

# rubocop:enable RSpec/ExampleLength, RSpec/MultipleExpectations
