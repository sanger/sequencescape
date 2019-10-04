# frozen_string_literal: true

require 'rails_helper'
require 'support/barcode_helper'

describe '/api/1/well-uuid' do
  let(:authorised_app) { create :api_application }
  let(:uuid) { well.uuid }
  let(:custom_metadata_uuid) { collection.uuid }
  let(:purpose_uuid) { '00000000-1111-2222-3333-666666666666' }

  let(:well) { create :well_with_sample_and_plate }
  let(:sample) { well.samples.first }

  before do
    well
  end

  describe '#get' do
    subject { '/api/1/' + uuid }

    let(:response_body) do
      %({
        "well": {
          "actions": {
            "read": "http://www.example.com/api/1/#{uuid}"
          },
          "aliquots": [
            {
              "sample": {
                "actions": {},
                "sanger": {}
              },
              "suboptimal": false
            }
          ],
          "uuid": "#{uuid}",
          "location": "#{well.map_description}",
          "state": "unknown"
        }
      })
    end
    let(:response_code) { 200 }

    it 'supports resource reading' do
      api_request :get, subject
      expect(JSON.parse(response.body)).to include_json(JSON.parse(response_body))
      expect(status).to eq(response_code)
    end
  end
end
