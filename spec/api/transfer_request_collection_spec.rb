# frozen_string_literal: true

require 'rails_helper'
require 'shared_contexts/limber_shared_context'

describe '/api/1/transfer_request_collection', transfer_request_collection: true do
  include_context 'a limber target plate with submissions'

  subject { '/api/1/transfer_request_collection' }

  let(:authorised_app) { create :api_application }

  let(:asset) { create :tagged_well }
  let(:target_asset) { create :empty_library_tube, barcode: 898 }
  let(:user) { create :user }
  let(:submission) { create :submission }

  describe '#post' do
    let(:payload) do
      %({
        "transfer_request_collection":{
          "user": "#{user.uuid}",
          "transfer_requests": [
            {
              "source_asset":"#{asset.uuid}",
              "target_asset": "#{target_asset.uuid}",
              "submission": "#{submission.uuid}",
              "volume": 10
            }
          ]
        }
      })
    end

    let(:response_body) do
      %({
        "transfer_request_collection": {
          "actions": {},
          "transfer_requests": [{
              "source_asset": { "uuid": "#{asset.uuid}"},
              "target_asset": { "uuid": "#{target_asset.receptacle.uuid}" },
              "submission": { "uuid": "#{submission.uuid}" }
          }],
          "target_tubes": [{
            "name": "#{target_asset.name}",
            "state": "pending",
            "barcode": {
              "prefix": "NT",
              "number": "898",
              "ean13": "#{target_asset.ean13_barcode}"
            }
          }],
          "user": {
            "uuid": "#{user.uuid}",
            "actions": {}
          }
        }
      })
    end
    let(:response_code) { 201 }

    it 'supports resource creation' do
      api_request :post, subject, payload
      expect(JSON.parse(response.body)).to include_json(JSON.parse(response_body))
      expect(status).to eq(response_code)
    end
  end
end
