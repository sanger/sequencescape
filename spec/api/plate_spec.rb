# frozen_string_literal: true

require 'rails_helper'
require 'support/barcode_helper'

describe '/api/1/plate-uuid' do
  subject { "/api/1/#{uuid}" }

  let(:authorised_app) { create(:api_application) }
  let(:uuid) { plate.uuid }

  let(:plate) { create(:plate, barcode: 'SQPD-1') }

  before { custom_metadata_collection }

  let(:custom_metadata_collection) { create(:custom_metadatum_collection, asset: plate) }

  let(:purpose) { plate.purpose }

  let(:response_body) do
    "{
      \"plate\": {
        \"actions\": {
          \"read\": \"http://www.example.com/api/1/#{uuid}\"
        },
        \"plate_purpose\": {
          \"actions\": {
            \"read\": \"http://www.example.com/api/1/#{purpose.uuid}\"
          }
        },
        \"wells\": {
          \"actions\": {
            \"read\": \"http://www.example.com/api/1/#{uuid}/wells\"
          }
        },
        \"submission_pools\": {
          \"actions\": {
            \"read\": \"http://www.example.com/api/1/#{uuid}/submission_pools\"
          }
        },
        \"custom_metadatum_collection\": {
          \"actions\": {
            \"read\": \"http://www.example.com/api/1/#{custom_metadata_collection.uuid}\"
          }
        },
        \"transfer_request_collections\": {
          \"size\": 0,
          \"actions\": {
            \"read\": \"http://www.example.com/api/1/#{uuid}/transfer_request_collections\"
          }
        },


        \"barcode\": {
          \"prefix\": \"SQPD\",
          \"number\": \"1\",
          \"type\": 1
        },

        \"stock_plate\": {
          \"barcode\": {}
        },

        \"uuid\": \"#{uuid}\"
      }
    }"
  end

  let(:response_code) { 200 }

  it 'supports resource reading' do
    api_request :get, subject
    expect(JSON.parse(response.body)).to include_json(JSON.parse(response_body))
    expect(status).to eq(response_code)
  end

  context 'with a stock plate' do
    let(:response_body) do
      "{
        \"plate\": {
          \"actions\": {
            \"read\": \"http://www.example.com/api/1/#{uuid}\"
          },
          \"plate_purpose\": {
            \"actions\": {
              \"read\": \"http://www.example.com/api/1/#{purpose.uuid}\"
            }
          },
          \"wells\": {
            \"actions\": {
              \"read\": \"http://www.example.com/api/1/#{uuid}/wells\"
            }
          },
          \"submission_pools\": {
            \"actions\": {
              \"read\": \"http://www.example.com/api/1/#{uuid}/submission_pools\"
            }
          },
          \"custom_metadatum_collection\": {
            \"actions\": {
              \"read\": \"http://www.example.com/api/1/#{custom_metadata_collection.uuid}\"
            }
          },
          \"transfer_request_collections\": {
            \"size\": 0,
            \"actions\": {
              \"read\": \"http://www.example.com/api/1/#{uuid}/transfer_request_collections\"
            }
          },


          \"barcode\": {
            \"prefix\": \"SQPD\",
            \"number\": \"1\",
            \"type\": 1,
            \"machine\": \"SQPD-1\"
          },

          \"stock_plate\": {
            \"barcode\": {
              \"number\":\"2\",
              \"prefix\":\"SQPD\",
              \"machine\":\"SQPD-2\"
            },
            \"uuid\":\"#{stock_plate&.uuid}\"
          },

          \"uuid\": \"#{uuid}\"
        }
      }"
    end

    let(:stock_plate) { create(:full_stock_plate, barcode: 'SQPD-2') }
    let(:plate) { create(:plate, parents: [stock_plate], barcode: 'SQPD-1') }
    let(:response_code) { 200 }

    it 'supports resource reading' do
      api_request :get, subject
      expect(JSON.parse(response.body)).to include_json(JSON.parse(response_body))
      expect(status).to eq(response_code)
    end
  end
end
