# frozen_string_literal: true

require 'rails_helper'
require 'support/barcode_helper'

describe '/api/1/asset_audits' do
  let(:authorised_app) { create(:api_application) }
  let(:labware) { create(:tube) }

  describe '#post' do
    subject(:resources) { '/api/1/asset_audits' }

    context 'without a labware' do
      let(:payload) do
        '{
          "asset_audit": {
            "message": "My message",
            "key": "some_key",
            "created_by": "john",
            "witnessed_by": "jane"
          }
        }'
      end

      let(:response_body) do
        "{
        \"content\": {
          \"asset\": [\"can't be blank\"]
        }
      }"
      end
      let(:response_code) { 422 }

      it 'prevents resource creation' do
        api_request :post, resources, payload
        expect(JSON.parse(response.body)).to include_json(JSON.parse(response_body))
        expect(status).to eq(response_code)
      end
    end

    context 'without a key' do
      let(:payload) { { asset_audit: { message: 'My message', created_by: 'john', asset: labware.uuid } }.to_json }

      let(:response_body) do
        '{
          "content": {
            "key": ["can\'t be blank", "Key can only contain letters, numbers or _"]
          }
        }'
      end
      let(:response_code) { 422 }

      it 'prevents resource creation' do
        api_request :post, resources, payload
        expect(JSON.parse(response.body)).to include_json(JSON.parse(response_body))
        expect(status).to eq(response_code)
      end
    end

    context 'with an invalid key' do
      let(:payload) do
        { asset_audit: { message: 'My message', key: '<key>', created_by: 'john', asset: labware.uuid } }.to_json
      end

      let(:response_body) do
        '{
          "content": {
            "key": ["Key can only contain letters, numbers or _"]
          }
        }'
      end
      let(:response_code) { 422 }

      it 'prevents resource creation' do
        api_request :post, resources, payload
        expect(JSON.parse(response.body)).to include_json(JSON.parse(response_body))
        expect(status).to eq(response_code)
      end
    end

    context 'with valid options' do
      let(:payload) do
        {
          asset_audit: {
            message: 'My message',
            key: 'some_key',
            created_by: 'john',
            asset: labware.uuid,
            witnessed_by: 'jane'
          }
        }.to_json
      end

      let(:response_body) do
        {
          asset_audit: {
            actions: {},
            created_by: 'john',
            key: 'some_key',
            message: 'My message',
            witnessed_by: 'jane',
            asset: {
              actions: {},
              uuid: labware.uuid
            }
          }
        }
      end
      let(:response_code) { 201 }

      it 'allows resource creation' do
        api_request :post, resources, payload
        expect(JSON.parse(response.body)).to include_json(response_body)
        expect(status).to eq(response_code)
      end
    end

    context 'with valid options and metadata' do
      let(:payload) do
        {
          asset_audit: {
            message: 'My message',
            key: 'some_key',
            created_by: 'john',
            asset: labware.uuid,
            witnessed_by: 'jane',
            metadata: {
              bed_1: 'plate_1'
            }
          }
        }.to_json
      end

      let(:response_body) do
        {
          asset_audit: {
            actions: {},
            created_by: 'john',
            key: 'some_key',
            message: 'My message',
            witnessed_by: 'jane',
            metadata: {
              bed_1: 'plate_1'
            },
            asset: {
              actions: {},
              uuid: labware.uuid
            }
          }
        }
      end
      let(:response_code) { 201 }

      it 'allows resource creation' do
        api_request :post, resources, payload
        expect(JSON.parse(response.body)).to include_json(response_body)
        expect(status).to eq(response_code)
      end
    end
  end

  describe '#get' do
    subject(:resource) { "/api/1/#{asset_audit.uuid}" }

    let(:asset_audit) { create(:asset_audit) }

    let(:response_body) do
      {
        asset_audit: {
          actions: {
            read: "http://www.example.com/api/1/#{asset_audit.uuid}"
          },
          uuid: asset_audit.uuid,
          created_by: 'abc123',
          key: asset_audit.key,
          message: asset_audit.message,
          witnessed_by: 'jane'
        }
      }
    end
    let(:response_code) { 200 }

    it 'allows resource creation' do
      api_request :get, resource
      expect(JSON.parse(response.body)).to include_json(response_body)
      expect(status).to eq(response_code)
    end
  end
end
