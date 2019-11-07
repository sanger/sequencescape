# frozen_string_literal: true

require 'rails_helper'
require 'support/barcode_helper'

describe '/api/1/multiplexed-library-tube-uuid' do
  let(:authorised_app) { create :api_application }
  let(:uuid) { tube.uuid }
  let(:custom_metadata_uuid) { collection.uuid }
  let(:purpose_uuid) { '00000000-1111-2222-3333-666666666666' }

  let(:purpose) { create :tube_purpose, :uuidable, uuid: purpose_uuid, name: 'Example purpose' }
  let(:tube) { create :multiplexed_library_tube, purpose: purpose, volume: 8.76000000 }
  let(:collection) { create(:custom_metadatum_collection, asset: tube) }

  before do
    tube
    collection
  end

  describe '#get' do
    subject { '/api/1/' + uuid }

    let(:response_body) do
      %{{
        "multiplexed_library_tube": {
          "actions": {
            "read": "http://www.example.com/api/1/#{uuid}"
          },
          "custom_metadatum_collection": {
            "actions": {
              "read": "http://www.example.com/api/1/#{custom_metadata_uuid}"
            }
          },
          "studies": {
            "size": 0,
            "actions": {
              "read": "http://www.example.com/api/1/#{uuid}/studies"
            }
          },
          "purpose": {
            "actions": {
              "read": "http://www.example.com/api/1/#{purpose_uuid}"
            },
            "name": "Example purpose"
          },
          "uuid": "#{uuid}",
          "volume": 8.76
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
end
