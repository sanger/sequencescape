# frozen_string_literal: true

require 'rails_helper'

describe 'Plates Heron API', with: :api_v2, tags: [:lighthouse, :heron] do
  describe '#create' do
    include BarcodeHelper

    before do
      mock_plate_barcode_service
    end

    let(:barcode) { '0000000001' }
    let(:request) { api_post '/api/v2/heron/plates', payload }
    let(:purpose) do
      create(:plate_purpose, target_type: 'Plate', name: 'Stock Plate', size: '96')
    end
    let(:plate) do
      request
      uuid = JSON.parse(response.body).dig('data', 'attributes', 'uuid')
      Plate.with_uuid(uuid).first
    end
    let(:url_for_plate) { JSON.parse(response.body).dig('data', 'links', 'self') }
    let(:error_messages) do
      request
      JSON.parse(response.body).dig('errors')
    end

    shared_examples_for 'a successful plate creation' do
      it 'returns 201' do
        request
        expect(response).to have_http_status(:created)
      end

      it 'can create a plate' do
        expect { request }.to change(Plate, :count).by(1)
        expect(url_for_plate).not_to be_nil
      end
    end

    shared_examples_for 'a failed plate creation' do
      it 'returns 422' do
        request
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it 'does not create a plate' do
        expect { request }.not_to change(Plate, :count)
      end
    end

    context 'when providing plate_purpose_uuid' do
      let(:payload) do
        {
          'data' => {
            'type' => 'plates',
            'attributes' => {
              'barcode' => barcode,
              'plate_purpose_uuid' => purpose.uuid
            }
          }
        }
      end

      it_behaves_like 'a successful plate creation'

      it 'has defined the plate purpose' do
        expect(plate.plate_purpose).to eq(purpose)
      end
    end

    context 'when not providing plate_purpose_uuid' do
      let(:payload) do
        {
          'data' => {
            'type' => 'plates',
            'attributes' => {
              'barcode' => barcode
            }
          }
        }
      end

      it_behaves_like 'a failed plate creation'

      it 'displays the error' do
        expect(error_messages).to eq([
          'You have to define either plate_purpose_uuid or plate_purpose'
        ])
      end
    end

    context 'when providing a barcode' do
      let(:payload) do
        {
          'data' => {
            'type' => 'plates',
            'attributes' => {
              'barcode': barcode,
              'plate_purpose_uuid' => purpose.uuid
            }
          }
        }
      end

      it_behaves_like 'a successful plate creation'

      it 'has defined the plate purpose' do
        expect(plate.plate_purpose).to eq(purpose)
      end
    end

    context 'when not providing a barcode' do
      let(:payload) do
        {
          'data' => {
            'type' => 'plates',
            'attributes' => {
              'plate_purpose_uuid' => purpose.uuid
            }
          }
        }
      end

      it_behaves_like 'a failed plate creation'

      it 'displays the error' do
        expect(error_messages).to eq([
          "Barcode can't be blank",
          "The barcode '' is not a recognised format."
        ])
      end
    end

    context 'when barcode has a wrong format' do
      let(:payload) do
        {
          'data' => {
            'type' => 'plates',
            'attributes' => {
              'plate_purpose_uuid' => purpose.uuid,
              'barcode' => '1234'
            }
          }
        }
      end

      it_behaves_like 'a failed plate creation'

      it 'displays the error' do
        expect(error_messages).to eq([
          "The barcode '1234' is not a recognised format."
        ])
      end
    end

    context 'when providing wells_content' do
      let(:study) { create(:study) }
      let!(:sample) { create(:sample) }
      let(:wells_content) do
        {
          'A01': { 'phenotype': 'A phenotype' },
          'B01': { 'sample_uuid': sample.uuid }
        }
      end
      let(:payload) do
        {
          'data' => {
            'type' => 'plates',
            'attributes' => {
              'barcode' => barcode,
              'study_uuid' => study.uuid,
              'plate_purpose_uuid' => purpose.uuid,
              'wells_content' => wells_content
            }
          }
        }
      end

      it_behaves_like 'a successful plate creation'

      it 'creates a new plate with that content' do
        expect { request }.to change(Sample, :count).by(1).and change(Aliquot, :count).by(2)
      end

      it 'has the defined study' do
        expect(plate.studies).to eq([study])
      end

      context 'when wells_content is wrong' do
        let(:wells_content) do
          {
            'A01': { 'asdf': 'A phenotype' },
            'B01': { 'phenotype': 'wrong', 'sample_uuid': sample.uuid }
          }
        end

        it_behaves_like 'a failed plate creation'

        it 'displays the error' do
          expect(error_messages).to eq([
            'Wells content A01 Asdf Unexisting field for sample or sample_metadata',
            'Wells content B01 Phenotype No other params can be added when sample uuid specified'
          ])
        end
      end

      context 'when not providing study' do
        let(:payload) do
          {
            'data' => {
              'type' => 'plates',
              'attributes' => {
                'barcode' => barcode,
                'plate_purpose_uuid' => purpose.uuid,
                'wells_content' => wells_content
              }
            }
          }
        end

        it_behaves_like 'a failed plate creation'

        it 'displays the error' do
          expect(error_messages).to eq([
            "Wells content A01 Study can't be blank"
          ])
        end
      end

      context 'when there is an exception during plate creation' do
        before do
          allow(::Sample).to receive(:with_uuid).with(sample.uuid).and_raise('BOOM!!')
        end

        it 'does not create any plates' do
          expect(Plate.count).to eq(0)
          expect { request }.to raise_error(RuntimeError)
          expect(Plate.count).to eq(0)
        end

        it 'does not create any samples' do
          expect(Sample.count).to eq(1)
          expect { request }.to raise_error(RuntimeError)
          expect(Sample.count).to eq(1)
        end

        it 'does not create any aliquots' do
          expect(Aliquot.count).to eq(0)
          expect { request }.to raise_error(RuntimeError)
          expect(Aliquot.count).to eq(0)
        end
      end
    end
  end
end
