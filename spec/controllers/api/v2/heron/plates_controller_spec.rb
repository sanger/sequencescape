# frozen_string_literal: true

require 'rails_helper'
require 'support/barcode_helper'

RSpec.describe Api::V2::Heron::PlatesController, :heron, type: :request do
  include BarcodeHelper

  let(:stock_plate_purpose) { PlatePurpose.stock_plate_purpose }
  let(:study) { create(:study, name: 'Study 1') }

  before { mock_plate_barcode_service }

  context 'when there is a plate with samples in the message' do
    let(:purpose_uuid) { stock_plate_purpose.uuid }
    let(:study_uuid) { study.uuid }
    let(:barcode) { 'DN12345678' }
    let(:params) do
      {
        data: {
          type: 'plates',
          attributes: {
            barcode: barcode,
            wells: {
              A01: {
                content: {
                  supplier_name: 'xyz123'
                }
              },
              A02: {
                content: {
                  supplier_name: 'xyz456'
                }
              }
            },
            purpose_uuid: purpose_uuid,
            study_uuid: study_uuid
          }
        }
      }.with_indifferent_access
    end
    let!(:before_plate_count) { Plate.count }

    before { post api_v2_heron_plates_path, params: }

    it 'creates a new plate successfully' do
      expect(response).to have_http_status(:created)
      expect(Plate.count).to eq(before_plate_count + 1)
    end

    it 'reponds with the expected data' do
      json = ActiveSupport::JSON.decode(response.body)
      expect(json['data'].length).to eq(2)
      expect(json['data']['attributes']['purpose_name']).to eq stock_plate_purpose.name
      expect(json['data']['attributes']['study_names']).to eq [study.name]
    end

    it 'fails if barcode is not unique with the barcode information' do
      post(api_v2_heron_plates_path, params:)
      expect(response).to have_http_status(:unprocessable_entity)
      json = ActiveSupport::JSON.decode(response.body)
      expect(json['errors']).to eq(["The barcode '#{barcode}' is already in use."])
    end
  end
end
