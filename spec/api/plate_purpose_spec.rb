# frozen_string_literal: true
require 'rails_helper'
require 'support/barcode_helper'

describe '/api/1/plate_purposes' do
  subject { '/api/1/plate_purposes' }

  before(:each) do
    create :transfer_request_type
  end

  let(:authorised_app) { create :api_application }
  let(:parent_purpose) { create :plate_purpose }

  context '#post' do
    let(:payload) do
      %{{
        "plate_purpose":{
          "name": "External Plate Purpose",
          "stock_plate": true,
          "input_plate": true,
          "parents": ["#{parent_purpose.uuid}"]
        }
      }}
    end

    let(:response_body) {
      %{{
        "plate_purpose": {
          "actions": {},
          "name": "External Plate Purpose",
          "stock_plate": true,
          "plates": {
            "actions": {}
          },
          "children": {
            "actions": {}
          }
        }
      }}
    }
    let(:response_code) { 201 }

    it 'supports resource creation' do
      api_request :post, subject, payload
      expect(JSON.parse(response.body)).to include_json(JSON.parse(response_body))
      expect(status).to eq(response_code)
      expect(Purpose.last).to be_a(PlatePurpose::Input)
    end
  end
end

describe '/api/1/plate-purpose-uuid' do
  let(:authorised_app) { create :api_application }
  let(:uuid) { '00000000-1111-2222-3333-444444444444' }
  before(:each) do
    create :plate_purpose, :uuidable, uuid: uuid, name: 'Example purpose'
  end

  context '#get' do
    subject { '/api/1/' + uuid }

    let(:response_body) do
      %{{
        "plate_purpose": {
          "actions": {
            "read": "http://www.example.com/api/1/00000000-1111-2222-3333-444444444444"
          },

          "uuid": "00000000-1111-2222-3333-444444444444",

          "name": "Example purpose",
          "plates": {
            "actions": {
              "read": "http://www.example.com/api/1/00000000-1111-2222-3333-444444444444/plates"
            }
          },
          "children": {
            "actions": {
              "read": "http://www.example.com/api/1/00000000-1111-2222-3333-444444444444/children"
            }
          }
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

  context 'plates/#post' do
    subject { '/api/1/' + uuid + '/plates' }

    let(:payload) { '{"plate":{}}' }

    context 'when authorized' do
      let(:response_code) { 201 }
      let(:response_body) {
        '{ "plate": {
          "actions": {},
          "wells": {
            "actions": {},
            "size": 96
          }
        }}'
      }

      it 'supports resource creation' do
        expect(PlateBarcode).to receive(:create).and_return(build(:plate_barcode, barcode: 1000))
        api_request :post, subject, payload
        expect(JSON.parse(response.body)).to include_json(JSON.parse(response_body))
        expect(status).to eq(response_code)
      end
    end

    context 'when unuthorized' do
      let(:response_code) { 501 }
      let(:response_body) {
        '{"general": [ "requested action is not supported on this resource" ]}'
      }

      it 'prevents resource creation' do
        user_api_request create(:user), :post, subject, payload
        expect(JSON.parse(response.body)).to include_json(JSON.parse(response_body))
        expect(status).to eq(response_code)
      end
    end
  end
end
