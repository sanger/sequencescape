# frozen_string_literal: true

require 'rails_helper'
require 'support/barcode_helper'

describe '/api/1/labware-uuid' do
  let(:authorised_app) { create(:api_application) }
  let(:uuid) { labware.uuid }
  let(:custom_metadata_uuid) { collection.uuid }
  let(:purpose_uuid) { '00000000-1111-2222-3333-666666666666' }

  let!(:labware) { create(:labware) }

  describe '#get' do
    subject(:url) { "/api/1/#{uuid}" }

    # We use asset for compatibility reasons.
    let(:response_body) do
      "{
        \"asset\": {
          \"actions\": {
            \"read\": \"http://www.example.com/api/1/#{uuid}\"
          },
          \"uuid\": \"#{uuid}\"
        }
      }"
    end
    let(:response_code) { 200 }

    it 'supports resource reading' do
      api_request :get, url
      expect(JSON.parse(response.body)).to include_json(JSON.parse(response_body))
      expect(status).to eq(response_code)
    end
  end
end
