# frozen_string_literal: true
require 'rails_helper'
require 'pry'
describe '/api/1/tube/purposes' do
  before(:each) do
    create :transfer_request_type
  end

  let(:authorised_app) { create :api_application }
  let(:parent_purpose) { create :plate_purpose }

  let(:payload) do
    %{{
      "tube_purpose":{
        "name":"Test Purpose",
        "target_type":"MultiplexedLibraryTube",
        "parents": ["#{parent_purpose.uuid}"],
        "type": "IlluminaHtp::InitialStockTubePurpose"
      }
    }}
  end

  let(:response_body) {
    %{{
      "tube_purpose":{
        "actions": { },
        "parents": { "size": 1 },
        "children": { "size": 0 },
        "tubes": { "size": 0 },
        "name":"Test Purpose"
      }
    }}
  }
  let(:response_code) { 201 }

  it 'supports resource creation' do
    api_request :post, subject, payload
    expect(JSON.parse(response.body)).to include_json(JSON.parse(response_body))
    expect(status).to eq(response_code)
  end

  it 'allows custom types to be defined' do
    api_request :post, subject, payload
    expect(Tube::Purpose.last).to be_a(IlluminaHtp::InitialStockTubePurpose)
  end

  # Move into a helper as this expands
  def api_request(action, path, body)
    headers = {
      'HTTP_ACCEPT' => 'application/json'
    }
    headers['CONTENT_TYPE'] = 'application/json' unless body.nil?
    headers['HTTP_X_SEQUENCESCAPE_CLIENT_ID'] = authorised_app.key
    yield(headers) if block_given?
    send(action.downcase, path, body, headers)
  end
end
