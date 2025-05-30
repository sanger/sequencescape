# frozen_string_literal: true

require 'rails_helper'
require 'support/barcode_helper'

describe '/api/1/plate-purpose-uuid' do
  let(:authorised_app) { create(:api_application) }
  let(:uuid) { '00000000-1111-2222-3333-444444444444' }

  before { create(:dilution_plate_purpose, :uuidable, uuid: uuid, name: 'Example purpose') }

  describe '#get' do
    subject(:url) { "/api/1/#{uuid}" }

    let(:response_body) do
      '{
        "dilution_plate_purpose": {
          "actions": {
            "read": "http://www.example.com/api/1/00000000-1111-2222-3333-444444444444"
          },

          "uuid": "00000000-1111-2222-3333-444444444444",

          "name": "Example purpose",
          "plates": {
            "actions": {
              "read": "http://www.example.com/api/1/00000000-1111-2222-3333-444444444444/plates"
            }
          }
        }
      }'
    end
    let(:response_code) { 200 }

    it 'supports resource reading' do
      api_request :get, url
      expect(JSON.parse(response.body)).to include_json(JSON.parse(response_body))
      expect(status).to eq(response_code)
    end
  end

  describe 'plates/#post' do
    subject(:url) { "/api/1/#{uuid}/plates" }

    let(:payload) { '{"plate":{}}' }

    context 'when authorized' do
      let(:response_code) { 201 }
      let(:response_body) do
        '{ "plate": {
          "actions": {},
          "wells": {
            "actions": {},
            "size": 96
          }
        }}'
      end

      it 'supports resource creation' do
        expect(PlateBarcode).to receive(:create_barcode).and_return(build(:plate_barcode))
        api_request :post, url, payload
        expect(JSON.parse(response.body)).to include_json(JSON.parse(response_body))
        expect(status).to eq(response_code)
      end
    end

    context 'when unuthorized' do
      let(:response_code) { 501 }
      let(:response_body) { '{"general": [ "requested action is not supported on this resource" ]}' }

      it 'prevents resource creation' do
        user_api_request create(:user), :post, url, payload
        expect(JSON.parse(response.body)).to include_json(JSON.parse(response_body))
        expect(status).to eq(response_code)
      end
    end
  end
end
