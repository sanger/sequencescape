# frozen_string_literal: true

require 'rails_helper'
require 'support/barcode_helper'

RSpec.describe Api::V2::Heron::TubeRacksController, type: :request, heron: true do
  before do
    create(:purpose, target_type: 'TubeRack', size: Heron::Factories::TubeRack::RACK_SIZE)
    create(:study, id: Heron::Factories::TubeRack::HERON_STUDY)
  end

  context 'when there is a tube rack message' do
    let(:tube_rack_barcode) { build(:fluidigm).barcode }
    let(:tubes_barcodes) { [build(:fluidx).barcode, build(:fluidx).barcode] }
    let(:tubes_locations) { ["A01", "B01"] }
    let(:supplier_sample_ids) { ["PHEC-nnnnnnn1", "PHEC-nnnnnnn2"] }
    let(:tubes) {
      [
              {
               "location": tubes_locations[0],
               "barcode": tubes_barcodes[0],
               "supplier_sample_id": supplier_sample_ids[0]
              },
              {
               "location": tubes_locations[1],
               "barcode": tubes_barcodes[1],
               "supplier_sample_id": supplier_sample_ids[1]
              }
      ]
    }
    let(:payload) {
      {
        "data": {
          "attributes": {
             "tube_rack": {
                "barcode": tube_rack_barcode,
                "tubes": tubes
             }
          }
        }
      }
    }
    let(:params) { payload.to_h.with_indifferent_access }

    shared_examples_for 'an incorrect tube rack message' do
      it 'does not create a tube rack' do
        expect do
          post api_v2_heron_tube_racks_path, params: params
        end.not_to change(TubeRack, :count)
      end
      it 'returns a 422 status code' do
        post api_v2_heron_tube_racks_path, params: params
        expect(response).to have_http_status(:unprocessable_entity)
      end
      it 'contains errors in the response' do
        post api_v2_heron_tube_racks_path, params: params
        expect(JSON.parse(response.body)['errors'].length > 0).to be_truthy
      end
    end

    it 'creates a new tube rack' do
      expect do
        post api_v2_heron_tube_racks_path, params: params
      end.to change(TubeRack, :count).by(1)
    end

    it 'returns a 201 status code' do
      post api_v2_heron_tube_racks_path, params: params
      expect(response).to have_http_status(:created)
    end

    context 'when there is some data missing/incorrect' do
      context 'when the tube rack doesnt have a barcode' do
        let(:tube_rack_barcode) { nil }
        it_behaves_like 'an incorrect tube rack message'
      end
      context 'when the tube rack doesnt have any tubes' do
        let(:tubes) { nil }
        it_behaves_like 'an incorrect tube rack message'
      end
      context 'when some tubes do not have a location' do
        let(:tubes_locations) { ["A01", nil] }
        it_behaves_like 'an incorrect tube rack message'
      end
      context 'when some tubes do not have a barcode' do
        let(:tubes_barcodes) { [build(:fluidx).barcode, nil] }
        it_behaves_like 'an incorrect tube rack message'
      end
      context 'when some tubes do not have a supplier sample id' do
        let(:supplier_sample_ids) { ["PHEC-nnnnnnn1", nil] }
        it_behaves_like 'an incorrect tube rack message'
      end
    end
  end
end
