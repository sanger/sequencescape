# frozen_string_literal: true

require 'rails_helper'
require 'support/barcode_helper'

RSpec.describe 'TubeRacks Heron API', with: :api_v2, lighthouse: true, heron: true do
  let(:size) { 96 }
  let(:purpose) { create(:purpose, type: 'TubeRack::Purpose', target_type: 'TubeRack', size: 96) }

  let(:request) { api_post '/api/v2/heron/tube_racks', payload }

  context 'when there is a tube rack message' do
    let(:study) { create(:study, id: Heron::Factories::TubeRack::HERON_STUDY) }
    let(:tube_rack_barcode) { build(:fluidigm).barcode }
    let(:tubes_barcodes) { [build(:fluidx).barcode, build(:fluidx).barcode] }
    let(:tubes_coordinates) { %w[A1 B1] }
    let(:supplier_sample_ids) { %w[PHEC-nnnnnnn1 PHEC-nnnnnnn2] }
    let(:tubes) do
      {
        "#{tubes_coordinates[0]}": {
          "barcode": tubes_barcodes[0],
          "content": { "supplier_name": supplier_sample_ids[0] }
        },
        "#{tubes_coordinates[1]}": {
          "barcode": tubes_barcodes[1],
          "content": { "supplier_name": supplier_sample_ids[1] }
        }
      }
    end
    let(:payload) do
      {
        "data": {
          "attributes": {
            "tube_rack": {
              "purpose_uuid": purpose.uuid,
              "study_uuid": study.uuid,
              "size": size,
              "barcode": tube_rack_barcode,
              "tubes": tubes
            }
          }
        }
      }
    end

    shared_examples_for 'an incorrect tube rack message' do
      it 'does not create a tube rack' do
        expect do
          request
        end.not_to change(TubeRack, :count)
      end

      it 'returns a 422 status code' do
        request
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it 'contains errors in the response' do
        request
        expect(!JSON.parse(response.body)['errors'].empty?).to be_truthy
      end
    end

    it 'creates a new tube rack' do
      expect do
        request
      end.to change(TubeRack, :count).by(1)
    end

    it 'returns a 201 status code' do
      request
      expect(response).to have_http_status(:created)
    end

    it 'writes the supplier name' do
      request
      expect(
        ::Sample::Metadata.joins(sample: { aliquots: { receptacle: :barcodes } }).where(barcodes: { barcode: tubes_barcodes }).map(&:supplier_name)
      ).to eq(supplier_sample_ids)
    end

    context 'when there is some data missing/incorrect' do
      context 'when there is not plate purpose that match the rack size' do
        let(:size) { 33 }

        it_behaves_like 'an incorrect tube rack message'
      end

      context 'when the tube rack doesnt have a barcode' do
        let(:tube_rack_barcode) { nil }

        it_behaves_like 'an incorrect tube rack message'
      end

      context 'when the tube rack doesnt have any tubes' do
        let(:tubes) { nil }

        it_behaves_like 'an incorrect tube rack message'
      end

      context 'when some tubes do not have a coordinate' do
        let(:tubes_coordinates) { ['A01', nil] }

        it_behaves_like 'an incorrect tube rack message'
      end

      context 'when some tubes do not have a barcode' do
        let(:tubes_barcodes) { [build(:fluidx).barcode, nil] }

        it_behaves_like 'an incorrect tube rack message'
      end
    end
  end
end
