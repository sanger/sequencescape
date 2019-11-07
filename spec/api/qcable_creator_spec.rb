# frozen_string_literal: true

require 'rails_helper'

describe '/api/1/qcable_creators' do
  subject { '/api/1/qcable_creators' }

  let(:authorised_app) { create :api_application }
  let(:user) { create :user }
  let(:lot) {  create :tag2_lot }
  let(:barcodes) { %w[CGAP-1 CGAP-2 CGAP-3 CGAP-4 CGAP-5] }

  describe '#post' do
    let(:payload) do
      %({"qcable_creator":{ "user": "#{user.uuid}", "lot": "#{lot.uuid}", "barcodes": "#{barcodes.join(',')}"}})
    end

    let(:response_body) do
      %({
        "qcable_creator": {
          "actions": {},
          "lot": {
            "actions": {
              "read": "http://www.example.com/api/1/#{lot.uuid}"
            }
          }
        }
      })
    end

    let(:response_code) { 201 }

    it 'returns the expected json' do
      api_request :post, subject, payload
      expect(JSON.parse(response.body)).to include_json(JSON.parse(response_body))
      expect(status).to eq(response_code)
    end

    it 'creates qcables for each barcode' do
      api_request :post, subject, payload

      lot.qcables.each_with_index do |qc, i|
        expect(qc.asset.external_barcode).to eq(barcodes[i])
      end
    end
  end
end
