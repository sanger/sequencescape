# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Heron::Factories::Plate, :heron, :heron_events, :lighthouse, type: :model do
  let(:purpose) { create(:plate_purpose, target_type: 'Plate', name: 'Stock Plate', size: '96') }
  let(:study) { create(:study) }
  let(:barcode) { '0000000001' }
  let(:params) { { purpose_uuid: purpose.uuid, barcode: } }

  include BarcodeHelper

  before { mock_plate_barcode_service }

  context 'with valid params' do
    let(:plate_factory) { described_class.new(params) }

    it 'can build a valid plate factory' do
      expect(plate_factory).to be_valid
    end
  end

  context 'with invalid params' do
    shared_examples_for 'an invalid parameter' do
      let(:factory) { described_class.new(params) }
      it 'is not valid' do
        expect(factory).not_to be_valid
      end

      it 'has an error' do
        factory.validate
        expect(factory.errors.full_messages).to eq(error_messages)
      end
    end

    context 'without a barcode' do
      let(:params) { { purpose_uuid: purpose.uuid } }
      let(:error_messages) { ["Barcode can't be blank", "The barcode '' is not a recognised format."] }

      it_behaves_like 'an invalid parameter'
    end

    context 'without a plate purpose uuid' do
      let(:params) { { barcode: } }
      let(:error_messages) { ['Plate purpose uuid not defined'] }

      it_behaves_like 'an invalid parameter'
    end

    context 'with a plate purpose uuid set to nil' do
      let(:params) { { purpose_uuid: nil, barcode: } }
      let(:error_messages) { ['Plate purpose for uuid () do not exist'] }

      it_behaves_like 'an invalid parameter'
    end

    context 'with a plate purpose uuid that do not exist' do
      let(:uuid) { SecureRandom.uuid }
      let(:params) { { purpose_uuid: uuid, barcode: } }
      let(:error_messages) { ["Plate purpose for uuid (#{uuid}) do not exist"] }

      it_behaves_like 'an invalid parameter'
    end
  end

  describe '#save' do
    let(:plate_factory) { described_class.new(params) }

    it 'can persist a new plate' do
      expect { plate_factory.save }.to change(Plate, :count).by(1)
    end

    it 'the plate has a purpose' do
      plate_factory.save

      expect(plate_factory.purpose.name).to eq 'Stock Plate'
    end

    it 'does not create several plates in subsequent calls' do
      expect(Plate.count).to eq(0)
      expect(plate_factory.save).to be_truthy
      expect(Plate.count).to eq(1)
      expect(plate_factory.save).to be_falsy
      expect(Plate.count).to eq(1)
    end

    context 'when providing samples information' do
      let!(:sample) { create(:sample) }
      let(:wells) do
        {
          A01: {
            content: {
              phenotype: 'A phenotype',
              study_uuid: study.uuid
            }
          },
          B01: {
            content: {
              phenotype: 'A phenotype',
              study_uuid: study.uuid
            }
          },
          C01: {
            content: {
              sample_uuid: sample.uuid
            }
          }
        }
      end
      let(:params) { { barcode:, purpose_uuid: purpose.uuid, wells: } }

      it 'persists the plate' do
        expect { plate_factory.save }.to change(Plate, :count).by(1)
      end

      it 'creates the new samples' do
        expect { plate_factory.save }.to change(Plate, :count).by(1).and(
          change(Sample, :count).by(2).and(change(Aliquot, :count).by(3))
        )
      end

      it 'allows you to fetch a unique list of study names' do
        plate_factory.save

        expect(plate_factory.sample_study_names).to eq [study.name]
      end

      context 'when there is an error in the sample info' do
        let(:wells) do
          {
            A01: {
              content: {
                wrong: 'wrong',
                study_uuid: study.uuid
              }
            },
            C01: {
              content: [{ phenotype: 'right' }, { sample_uuid: sample.uuid, phenotype: 'wrong' }]
            }
          }
        end

        it 'is invalid' do
          expect(plate_factory).not_to be_valid
        end

        it 'stores the error message from samples' do
          expect(plate_factory.tap(&:validate).errors.full_messages).to eq(
            [
              'Content a1 ["Wrong Unexisting field for sample or sample_metadata"]',
              "Content c1, pos: 0 [\"Study can't be blank\"]",
              'Content c1, pos: 1 ["Phenotype No other params can be added when sample uuid specified"]'
            ]
          )
        end
      end
    end

    context 'when declaring events' do
      let(:params) { { barcode:, purpose_uuid: purpose.uuid, events: [event] } }
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
      let(:event_type) { BroadcastEvent::PlateCherrypicked::EVENT_TYPE }
      let(:event) { { event: { event_type:, subjects: } } }

      it 'can persist the events' do
        expect { plate_factory.save }.to change(BroadcastEvent, :count).by(1)
      end
    end
  end
end
