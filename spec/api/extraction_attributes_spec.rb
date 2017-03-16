require 'rails_helper'
require 'support/barcode_helper'

describe '/api/1/extraction_attributes' do

  let(:target_plate) { create :plate }

  subject { "/api/1/#{target_plate.uuid}/extraction_attributes" }

  let(:authorised_app) { create :api_application }
  
  let(:user) { create :user }

  context '#post' do
    let(:payload) do
      %{{
        "extraction_attribute":{
          "created_by": "#{user.name}",
          "attributes_update": {
            "wells": [
            ]
          }
        }
      }}
    end

    let(:response_code) { 201 }

    it 'supports resource creation' do
      authorized_api_request :post, subject, payload
      expect(JSON.parse(response.body)).to include_json(JSON.parse(payload))
      expect(status).to eq(response_code)
    end

  end

  # Move into a helper as this expands
  def authorized_api_request(action, path, body)
    headers = {
      'HTTP_ACCEPT' => 'application/json'
    }
    headers['CONTENT_TYPE'] = 'application/json' unless body.nil?
    headers['HTTP_X_SEQUENCESCAPE_CLIENT_ID'] = authorised_app.key
    yield(headers) if block_given?
    send(action.downcase, path, body, headers)
  end

end
