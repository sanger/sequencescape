# Lab events are part of the old pipelines
# They track metadata as batches progress through the pipeline
# frozen_string_literal: true

require 'rails_helper'

RSpec.describe BroadcastEvent::QcAssay, :broadcast_event do
  subject do
    described_class.create!(
      seed: qc_assay,
      created_at: Time.zone.parse('2018-01-12T13:37:03+00:00'),
      properties: {
        'assay_type' => 'Example Assay'
      }
    )
  end

  let(:json) { JSON.parse(subject.to_json) }
  let(:lot_number) { '12345' }
  let(:plate) { create(:plate_with_untagged_wells, sample_count: 2, studies: [study], parents: [stock_plate]) }
  let(:stock_plate) { create(:stock_plate, purpose: PlatePurpose.stock_plate_purpose, well_count: 2) }
  let(:study) { create(:study) }
  let(:well1) { plate.wells[0] }
  let(:sample1) { well1.samples.first }
  let(:well2) { plate.wells[1] }
  let(:sample2) { well2.samples.first }

  context 'A single assay qc_assay' do
    let(:qc_assay) do
      create(
        :qc_assay,
        lot_number:,
        qc_results: [
          build(:qc_result_concentration, asset: well1, assay_type: 'Example Assay', assay_version: 'v0.0'),
          build(:qc_result_concentration, asset: well2, assay_type: 'Example Assay', assay_version: 'v0.0')
        ]
      )
    end

    describe '#to_json' do
      it 'generates json' do
        expect(json).not_to be_nil
      end

      it 'sets the event type based on the qc_assay' do
        expect(json).to include_json('event' => { 'event_type' => 'quant_example_assay' })
      end

      it 'sends the lot number as metadata' do
        expect(json).to include_json(
          'event' => {
            'metadata' => {
              'lot_number' => lot_number,
              'assay_version' => 'v0.0'
            }
          }
        )
      end

      it 'includes the expected subjects' do
        expect(json.dig('event', 'subjects')).to match_unordered_json(
          [
            { 'role_type' => 'study', 'subject_type' => 'study', 'uuid' => study.uuid, 'friendly_name' => study.name },
            {
              'role_type' => 'sample',
              'subject_type' => 'sample',
              'uuid' => sample1.uuid,
              'friendly_name' => sample1.name
            },
            {
              'role_type' => 'sample',
              'subject_type' => 'sample',
              'uuid' => sample2.uuid,
              'friendly_name' => sample2.name
            },
            {
              'role_type' => 'assayed_labware',
              'subject_type' => 'plate',
              'uuid' => plate.uuid,
              'friendly_name' => plate.human_barcode
            },
            {
              'role_type' => 'stock_plate',
              'subject_type' => 'plate',
              'uuid' => stock_plate.uuid,
              'friendly_name' => stock_plate.human_barcode
            }
          ]
        )
      end
    end

    describe '::generate_events' do
      it 'generates a single event' do
        events = described_class.generate_events(qc_assay)
        expect(events.length).to eq(1)
      end
    end
  end

  context 'A multi-assay qc_assay' do
    # The API supports multiple different assays types being conducted at the same time,
    # but event wise these should be distinguishable.
    let(:qc_assay) do
      create(
        :qc_assay,
        lot_number:,
        qc_results: [
          build(:qc_result_concentration, asset: well1, assay_type: 'Example Assay', assay_version: 'v0.0'),
          build(:qc_result_concentration, asset: well2, assay_type: 'Other Assay', assay_version: 'v0.0')
        ]
      )
    end

    describe '#to_json' do
      it 'generates json' do
        expect(json).not_to be_nil
      end

      it 'sets the event type based on the qc_assay' do
        expect(json).to include_json('event' => { 'event_type' => 'quant_example_assay' })
      end

      it 'sends the lot number as metadata' do
        expect(json).to include_json(
          'event' => {
            'metadata' => {
              'lot_number' => lot_number,
              'assay_version' => 'v0.0'
            }
          }
        )
      end

      it 'includes the expected subjects' do
        expect(json.dig('event', 'subjects')).to match_unordered_json(
          [
            { 'role_type' => 'study', 'subject_type' => 'study', 'uuid' => study.uuid, 'friendly_name' => study.name },
            {
              'role_type' => 'sample',
              'subject_type' => 'sample',
              'uuid' => sample1.uuid,
              'friendly_name' => sample1.name
            },
            {
              'role_type' => 'assayed_labware',
              'subject_type' => 'plate',
              'uuid' => plate.uuid,
              'friendly_name' => plate.human_barcode
            },
            {
              'role_type' => 'stock_plate',
              'subject_type' => 'plate',
              'uuid' => stock_plate.uuid,
              'friendly_name' => stock_plate.human_barcode
            }
          ]
        )
      end
    end

    describe '::generate_events' do
      # In the event we have two different assay types bundled together, we generate two different events, and separate
      # them via the properties.
      it 'generates a two events' do
        events = described_class.generate_events(qc_assay)
        expect(events.length).to eq(2)
        expect(events.map(&:properties)).to include(assay_type: 'Example Assay', assay_version: 'v0.0')
        expect(events.map(&:properties)).to include(assay_type: 'Other Assay', assay_version: 'v0.0')
      end
    end
  end
end
