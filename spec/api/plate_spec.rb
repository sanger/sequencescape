# frozen_string_literal: true
require 'rails_helper'
require 'support/barcode_helper'

describe '/api/1/plate-uuid' do
  subject { '/api/1/' + uuid }

  let(:authorised_app) { create :api_application }
  let(:uuid) { plate.uuid }

  let(:plate) do
    create :plate, barcode: '1'
  end

  before do
    custom_metadata_collection
  end
  let(:custom_metadata_collection) do
    create(:custom_metadatum_collection, asset: plate)
  end

  let(:purpose) { plate.purpose }

  let(:response_body) do
    %{{
      "plate": {
        "actions": {
          "read": "http://www.example.com/api/1/#{uuid}"
        },
        "plate_purpose": {
          "actions": {
            "read": "http://www.example.com/api/1/#{purpose.uuid}"
          }
        },
        "wells": {
          "actions": {
            "read": "http://www.example.com/api/1/#{uuid}/wells"
          }
        },
        "submission_pools": {
          "actions": {
            "read": "http://www.example.com/api/1/#{uuid}/submission_pools"
          }
        },
        "custom_metadatum_collection": {
          "actions": {
            "read": "http://www.example.com/api/1/#{custom_metadata_collection.uuid}"
          }
        },
        "transfer_request_collections": {
          "size": 0,
          "actions": {
            "read": "http://www.example.com/api/1/#{uuid}/transfer_request_collections"
          }
        },


        "barcode": {
          "prefix": "DN",
          "number": "1",
          "ean13": "1220000001831",
          "type": 1
        },

        "uuid": "#{uuid}"
      }
    }}
  end

    let(:response_code) { 200 }

    it 'supports resource reading' do
      api_request :get, subject
      expect(JSON.parse(response.body)).to include_json(JSON.parse(response_body))
      expect(status).to eq(response_code)
    end
end
