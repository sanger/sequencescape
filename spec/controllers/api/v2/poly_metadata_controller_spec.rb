# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Api::V2::PolyMetadataController, type: :request do
  describe 'POST /api/v2/poly_metadata/bulk_create' do
    let(:aliquot) { create(:aliquot) }
    let(:valid_payload) do
      {
        data: [
          {
            type: 'poly_metadata',
            attributes: {
              key: 'key_1',
              value: 'value_1'
            },
            relationships: {
              metadatable: {
                data: { type: 'aliquot', id: aliquot.id.to_s }
              }
            }
          },
          {
            type: 'poly_metadata',
            attributes: {
              key: 'key_2',
              value: 'value_2'
            },
            relationships: {
              metadatable: {
                data: { type: 'aliquot', id: aliquot.id.to_s }
              }
            }
          }
        ]
      }
    end

    let(:expected_returned_data) do
      [
      {
        "id" => PolyMetadatum.first.id.to_s,
        "type" => "poly_metadata",
        "attributes" => { "key" => "key_1", "value" => "value_1" },
        "relationships" => {
          "metadatable" => {
            "data" => { "type" => "aliquot", "id" => aliquot.id.to_s }
          }
        }
      },
      {
        "id" => PolyMetadatum.second.id.to_s,
        "type" => "poly_metadata",
        "attributes" => { "key" => "key_2", "value" => "value_2" },
        "relationships" => {
          "metadatable" => {
            "data" => { "type" => "aliquot", "id" => aliquot.id.to_s }
          }
        }
      }
    ]
      end

    it 'creates multiple poly metadata records' do
      expect do
        post '/api/v2/poly_metadata/bulk_create',
             params: valid_payload,
             as: :json
      end.to change(PolyMetadatum, :count).by(2)

      expect(response).to have_http_status(:created)
      body = JSON.parse(response.body)

      expect(body["data"]).to match_array(expected_returned_data)
    end

    it 'rolls back transaction if one record fails' do
      bad_payload = valid_payload.dup
      bad_payload[:data] << {
        type: 'poly_metadata',
        attributes: { key: nil, value: 'missing key' }, # invalid
        relationships: { metadatable: { data: { type: 'aliquot', id: aliquot.id.to_s } } }
      }
      expect do
        expect do
          post '/api/v2/poly_metadata/bulk_create',
               params: bad_payload,
               as: :json
        end.to raise_error(ActiveRecord::RecordInvalid, /Key can't be blank/)
      end.not_to change(PolyMetadatum, :count)
    end
  end
end
