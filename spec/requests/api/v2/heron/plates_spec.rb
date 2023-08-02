# frozen_string_literal: true

require 'rails_helper'

describe 'Plates Heron API', heron: true, heron_events: true, lighthouse: true, with: :api_v2 do
  describe '#create' do
    include BarcodeHelper

    before { mock_plate_barcode_service }

    let(:barcode) { '0000000001' }
    let(:request) { api_post '/api/v2/heron/plates', payload }
    let(:purpose) { create(:plate_purpose, target_type: 'Plate', name: 'Stock Plate', size: '96') }
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

    context 'when providing purpose_uuid' do
      let(:payload) do
        { 'data' => { 'type' => 'plates', 'attributes' => { 'barcode' => barcode, 'purpose_uuid' => purpose.uuid } } }
      end

      it_behaves_like 'a successful plate creation'

      it 'has defined the plate purpose' do
        expect(plate.plate_purpose).to eq(purpose)
      end
    end

    context 'when not providing purpose_uuid' do
      let(:payload) { { 'data' => { 'type' => 'plates', 'attributes' => { 'barcode' => barcode } } } }

      it_behaves_like 'a failed plate creation'

      it 'displays the error' do
        expect(error_messages).to eq(['Plate purpose uuid not defined'])
      end
    end

    context 'when providing a barcode' do
      let(:payload) do
        { 'data' => { 'type' => 'plates', 'attributes' => { :barcode => barcode, 'purpose_uuid' => purpose.uuid } } }
      end

      it_behaves_like 'a successful plate creation'

      it 'has defined the plate purpose' do
        expect(plate.plate_purpose).to eq(purpose)
      end
    end

    context 'when not providing a barcode' do
      let(:payload) { { 'data' => { 'type' => 'plates', 'attributes' => { 'purpose_uuid' => purpose.uuid } } } }

      it_behaves_like 'a failed plate creation'

      it 'displays the error' do
        expect(error_messages).to eq(["Barcode can't be blank", "The barcode '' is not a recognised format."])
      end
    end

    context 'when barcode has a wrong format' do
      let(:payload) do
        { 'data' => { 'type' => 'plates', 'attributes' => { 'purpose_uuid' => purpose.uuid, 'barcode' => '1234' } } }
      end

      it_behaves_like 'a failed plate creation'

      it 'displays the error' do
        expect(error_messages).to eq(["The barcode '1234' is not a recognised format."])
      end
    end

    context 'when providing wells' do
      let(:study) { create(:study) }
      let!(:sample) { create(:sample) }
      let(:wells) { { A01: { content: { phenotype: 'A phenotype' } }, B01: { content: { sample_uuid: sample.uuid } } } }
      let(:payload) do
        {
          'data' => {
            'type' => 'plates',
            'attributes' => {
              'barcode' => barcode,
              'study_uuid' => study.uuid,
              'purpose_uuid' => purpose.uuid,
              'wells' => wells
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

      context 'when wells is wrong' do
        let(:wells) do
          {
            A01: {
              content: {
                asdf: 'A phenotype'
              }
            },
            B01: {
              content: {
                phenotype: 'wrong',
                sample_uuid: sample.uuid
              }
            }
          }
        end

        it_behaves_like 'a failed plate creation'

        it 'displays the error' do
          expect(error_messages).to eq(
            [
              'Content a1 Asdf Unexisting field for sample or sample_metadata',
              'Content b1 Phenotype No other params can be added when sample uuid specified'
            ]
          )
        end
      end

      context 'when not providing study' do
        let(:payload) do
          {
            'data' => {
              'type' => 'plates',
              'attributes' => {
                'barcode' => barcode,
                'purpose_uuid' => purpose.uuid,
                'wells' => wells
              }
            }
          }
        end

        it_behaves_like 'a failed plate creation'

        it 'displays the error' do
          expect(error_messages).to eq(["Content a1 Study can't be blank"])
        end
      end

      context 'when there is an exception during plate creation' do
        before { allow(::Sample).to receive(:with_uuid).with(sample.uuid).and_raise('BOOM!!') }

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

    context 'when providing events' do
      let(:study) { create(:study) }
      let!(:sample) { create(:sample) }
      let(:wells) { { A01: { content: { phenotype: 'A phenotype' } }, B01: { content: { sample_uuid: sample.uuid } } } }
      let(:payload) do
        {
          'data' => {
            'type' => 'plates',
            'attributes' => {
              'barcode' => barcode,
              'study_uuid' => study.uuid,
              'purpose_uuid' => purpose.uuid,
              'wells' => wells,
              'events' => events
            }
          }
        }
      end
      let(:subjects) do
        [
          build(
            :event_subject,
            role_type: BroadcastEvent::PlateCherrypicked::SOURCE_PLATES_ROLE_TYPE,
            subject_type: 'plate'
          ),
          build(:event_subject, role_type: BroadcastEvent::PlateCherrypicked::SAMPLE_ROLE_TYPE, subject_type: 'sample'),
          build(:event_subject, role_type: BroadcastEvent::PlateCherrypicked::ROBOT_ROLE_TYPE, subject_type: 'robot')
        ]
      end
      let(:events) { [{ event: { event_type: BroadcastEvent::PlateCherrypicked::EVENT_TYPE, subjects: subjects } }] }

      it_behaves_like 'a successful plate creation'

      it 'creates the event for the plate provided' do
        expect(BroadcastEvent::PlateCherrypicked.where(seed: plate).count).to eq(1)
      end

      context 'when missing required subjects in the events part' do
        let(:subjects) do
          [
            build(
              :event_subject,
              role_type: BroadcastEvent::PlateCherrypicked::SOURCE_PLATES_ROLE_TYPE,
              subject_type: 'plate'
            ),
            build(:event_subject, role_type: BroadcastEvent::PlateCherrypicked::ROBOT_ROLE_TYPE, subject_type: 'robot')
          ]
        end

        it_behaves_like 'a failed plate creation'

        it 'displays the error' do
          expect(error_messages).to eq(
            ["Samples is a required subject needed for the event 'lh_beckman_cp_destination_created'"]
          )
        end
      end
    end
  end
end
