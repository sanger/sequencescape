# frozen_string_literal: true

require 'rails_helper'
require 'support/barcode_helper'

RSpec.describe 'TubeRacks Heron API', with: :api_v2, lighthouse: true, heron: true do
  let(:size) { 96 }
  let(:purpose) { create(:purpose, type: 'TubeRack::Purpose', target_type: 'TubeRack', size: 96) }

  let(:request) { api_post '/api/v2/heron/tube_racks', payload }

  context 'when there is a tube rack message' do
    let(:study) { create(:study) }
    let(:tube_rack_barcode) { build(:fluidigm).barcode }
    let(:tubes_barcodes) { [build(:fluidx).barcode, build(:fluidx).barcode] }
    let(:tubes_coordinates) { %w[A1 B1] }
    let(:supplier_sample_ids) { %w[PHEC-nnnnnnn1 PHEC-nnnnnnn2] }
    let(:purpose_uuid) { purpose.uuid }
    let(:rack) do
      uuid = JSON.parse(response.body).dig('data', 'attributes', 'uuid')
      TubeRack.with_uuid(uuid).first
    end
    let(:url_for_rack) { JSON.parse(response.body).dig('data', 'links', 'self') }

    let(:tubes) do
      {
        "#{tubes_coordinates[0]}": {
          barcode: tubes_barcodes[0],
          content: {
            supplier_name: supplier_sample_ids[0]
          }
        },
        "#{tubes_coordinates[1]}": {
          barcode: tubes_barcodes[1],
          content: {
            supplier_name: supplier_sample_ids[1]
          }
        }
      }
    end
    let(:payload) do
      {
        data: {
          'type' => 'tube_rack',
          :attributes => {
            purpose_uuid: purpose_uuid,
            study_uuid: study.uuid,
            barcode: tube_rack_barcode,
            tubes: tubes
          }
        }
      }
    end

    shared_examples_for 'a failed tube rack creation' do
      it 'does not create a tube rack' do
        expect { request }.not_to change(TubeRack, :count)
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

    shared_examples_for 'a successful tube rack creation' do
      it 'creates a new tube rack' do
        expect { request }.to change(TubeRack, :count).by(1)
      end

      it 'returns a 201 status code' do
        request
        expect(response).to have_http_status(:created)
      end

      it 'returns the uuid of the rack' do
        request
        expect(rack).not_to be_nil
      end

      it 'returns the url for the created rack' do
        request
        expect(url_for_rack).not_to be_nil
      end
    end

    context 'with a correct message' do
      context 'when the message specifies supplier name for the samples' do
        it_behaves_like 'a successful tube rack creation'

        it 'writes the supplier name' do
          request
          expect(
            ::Sample::Metadata
              .joins(sample: { aliquots: { receptacle: :barcodes } })
              .where(barcodes: { barcode: tubes_barcodes })
              .map(&:supplier_name)
          ).to eq(supplier_sample_ids)
        end
      end

      context 'when the message specifies control and control_type for the samples' do
        let(:tubes) do
          {
            "#{tubes_coordinates[0]}": {
              barcode: tubes_barcodes[0],
              content: {
                control: true,
                control_type: 'positive'
              }
            },
            "#{tubes_coordinates[1]}": {
              barcode: tubes_barcodes[1],
              content: {
                control: false,
                control_type: nil
              }
            }
          }
        end

        it_behaves_like 'a successful tube rack creation'

        it 'writes the control' do
          request
          expect(
            ::Sample
              .joins(aliquots: { receptacle: :barcodes })
              .where(barcodes: { barcode: tubes_barcodes })
              .map(&:control)
          ).to eq([true, false])
        end

        it 'writes the control type' do
          request
          expect(
            ::Sample
              .joins(aliquots: { receptacle: :barcodes })
              .where(barcodes: { barcode: tubes_barcodes })
              .map(&:control_type)
          ).to eq(['positive', nil])
        end
      end
    end

    context 'when there is some data missing/incorrect' do
      context 'when the tube rack doesnt have a purpose uuid' do
        let(:purpose_uuid) { nil }

        it_behaves_like 'a failed tube rack creation'
      end

      context 'when there is not plate purpose that match the uuid' do
        let(:purpose_uuid) { SecureRandom.uuid }

        it_behaves_like 'a failed tube rack creation'
      end

      context 'when the tube rack doesnt have a barcode' do
        let(:tube_rack_barcode) { nil }

        it_behaves_like 'a failed tube rack creation'
      end

      context 'when the tube rack doesnt have any tubes' do
        let(:tubes) { nil }

        it_behaves_like 'a failed tube rack creation'
      end

      context 'when some tubes do not have a coordinate' do
        let(:tubes_coordinates) { ['A01', nil] }

        it_behaves_like 'a failed tube rack creation'
      end

      context 'when some tubes do not have a barcode' do
        let(:tubes_barcodes) { [build(:fluidx).barcode, nil] }

        it_behaves_like 'a failed tube rack creation'
      end
    end
  end
end
