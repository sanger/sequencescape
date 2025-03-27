# frozen_string_literal: true

require 'rails_helper'
require 'support/barcode_helper'

RSpec.describe Api::V2::Heron::TubeRacksController, :heron, type: :request do
  include BarcodeHelper

  let!(:purpose_96) { create(:tube_rack_purpose, target_type: 'TubeRack', size: 96) }
  let(:study) { create(:study, name: 'Study 1') }

  before { mock_plate_barcode_service }

  context 'when there is a tube rack with tubes with samples in the message' do
    let(:purpose_96_uuid) { purpose_96.uuid }
    let(:study_uuid) { study.uuid }
    let(:params) do
      {
        data: {
          type: 'tube_racks',
          attributes: {
            barcode: 'FE12345678',
            tubes: {
              'A01' => {
                barcode: 'FD00000001',
                content: {
                  supplier_name: 'PHEC-nnnnnnn1'
                }
              },
              'A02' => {
                barcode: 'FD00000002',
                content: {
                  supplier_name: 'PHEC-nnnnnnn2'
                }
              }
            },
            purpose_uuid: purpose_96_uuid,
            study_uuid: study_uuid
          }
        }
      }.with_indifferent_access
    end
    let!(:before_tube_rack_count) { TubeRack.count }
    let!(:before_tube_count) { Tube.count }

    before { post api_v2_heron_tube_racks_path, params: }

    it 'creates a new tube rack successfully' do
      expect(response).to have_http_status(:created)
      expect(TubeRack.count).to eq(before_tube_rack_count + 1)
      expect(Tube.count).to eq(before_tube_count + 2)
    end

    it 'reponds with the expected data' do
      json = ActiveSupport::JSON.decode(response.body)
      expect(json['data'].length).to eq(2)
      expect(json['data']['attributes']['purpose_name']).to eq purpose_96.name
      expect(json['data']['attributes']['study_names']).to eq [study.name]
    end
  end
end
