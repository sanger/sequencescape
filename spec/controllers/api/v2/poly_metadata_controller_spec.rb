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
            attributes: { key: 'key_1', value: 'value_1' },
            relationships: {
              metadatable: { data: { type: 'aliquots', id: aliquot.id.to_s } }
            }
          },
          {
            type: 'poly_metadata',
            attributes: { key: 'key_2', value: 'value_2' },
            relationships: {
              metadatable: { data: { type: 'aliquots', id: aliquot.id.to_s } }
            }
          }
        ]
      }
    end

    describe 'with valid payload' do
      before do
        post '/api/v2/poly_metadata/bulk_create', params: valid_payload, as: :json
      end

      it 'creates the expected number of records' do
        expect(PolyMetadatum.count).to eq(2)
      end

      it 'returns status created' do
        expect(response).to have_http_status(:created)
      end

      it 'returns the created poly_metadata records' do
        body = response.parsed_body
        ids = PolyMetadatum.pluck(:id).map(&:to_s)

        expect(body['data']).to contain_exactly({
                                                  'id' => ids.first,
                                                  'type' => 'poly_metadata',
                                                  'attributes' => { 'key' => 'key_1', 'value' => 'value_1' },
                                                  'relationships' => {
                                                    'metadatable' => {
                                                      'data' => { 'type' => 'aliquots', 'id' => aliquot.id.to_s }
                                                    }
                                                  }
                                                }, {
                                                  'id' => ids.second,
                                                  'type' => 'poly_metadata',
                                                  'attributes' => { 'key' => 'key_2', 'value' => 'value_2' },
                                                  'relationships' => {
                                                    'metadatable' => {
                                                      'data' => { 'type' => 'aliquots', 'id' => aliquot.id.to_s }
                                                    }
                                                  }
                                                })
      end
    end

    describe 'with invalid payload' do
      let(:bad_payload) do
        valid_payload.deep_dup.tap do |payload|
          payload[:data] << {
            type: 'poly_metadata',
            attributes: { key: nil, value: 'missing key' }, # invalid
            relationships: {
              metadatable: { data: { type: 'aliquots', id: aliquot.id.to_s } }
            }
          }
        end
      end

      before do
        post '/api/v2/poly_metadata/bulk_create', params: bad_payload, as: :json
      end

      it 'does not create any records' do
        expect(PolyMetadatum.count).to eq(0)
      end

      it 'raises a validation error' do
        expect(response.parsed_body['error']).to
        eq("PolyMetadatum bulk creation failed: Validation failed: Key can't be blank")
      end
    end
  end
end
