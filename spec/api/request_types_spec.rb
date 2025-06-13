# frozen_string_literal: true

require 'rails_helper'
require 'support/barcode_helper'

describe '/api/1/request-type-uuid' do
  let(:authorised_app) { create(:api_application) }
  let(:uuid) { '00000000-1111-2222-3333-444444444444' }

  before { create(:request_type, :uuidable, uuid: uuid, name: 'Sequencing by colour') }

  describe '#get' do
    subject(:url) { "/api/1/#{uuid}" }

    let(:response_body) do
      '{
        "request_type": {
          "actions": {
            "read": "http://www.example.com/api/1/00000000-1111-2222-3333-444444444444"
          },

          "uuid": "00000000-1111-2222-3333-444444444444",
          "name": "Sequencing by colour"
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
end
