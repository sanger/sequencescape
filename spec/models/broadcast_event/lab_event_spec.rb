# Lab events are part of the old pipelines
# They track metadata as batches progress through the pipeline
# frozen_string_literal: true

require 'rails_helper'

RSpec.describe BroadcastEvent::LabEvent, :broadcast_event do
  subject do
    described_class.create!(seed: lab_event, user: user, created_at: Time.zone.parse('2018-01-12T13:37:03+00:00'))
  end

  let(:json) { JSON.parse(subject.to_json) }
  let(:eventful) { request }
  let(:batch) { create(:sequencing_batch) }
  let(:study) { create(:study) }
  let!(:request) do
    create(
      :sequencing_request_with_assets,
      batch: batch,
      request_type: batch.pipeline.request_types.first,
      study: study
    )
  end
  let(:sample) { request.asset.samples.first }
  let(:stock_asset) { request.asset.labware }

  let(:lab_event) do
    create(
      :lab_event,
      description: 'Read 1 Lin/block/hyb/load',
      descriptors: {
        'key_a' => 'value a',
        'key_b' => 'value b'
      },
      eventful: eventful
    )
  end
  let(:user) { create(:user) }

  it 'generates json' do
    expect(json).not_to be_nil
  end

  it 'sets the event type based on the lab event' do
    expect(json).to include_json('event' => { 'event_type' => 'read_1_lin_block_hyb_load' })
  end

  it 'grabs the metadata verbatim from the descriptors hash' do
    expect(json).to include_json('event' => { 'metadata' => { 'key_a' => 'value a', 'key_b' => 'value b' } })
  end

  context 'from a sequencing batch' do
    let(:eventful) { batch.reload }

    it 'includes the expected subjects' do
      expect(json.dig('event', 'subjects')).to match_unordered_json(
        [
          {
            'role_type' => 'flowcell',
            'subject_type' => 'flowcell',
            'uuid' => batch.uuid,
            'friendly_name' => batch.id
          },
          { 'role_type' => 'study', 'subject_type' => 'study', 'uuid' => study.uuid, 'friendly_name' => study.name },
          {
            'role_type' => 'sample',
            'subject_type' => 'sample',
            'uuid' => sample.uuid,
            'friendly_name' => sample.name
          },
          {
            'role_type' => 'sequencing_source_labware',
            'subject_type' => 'tube',
            'uuid' => stock_asset.uuid,
            'friendly_name' => stock_asset.human_barcode
          }
        ]
      )
    end
  end

  context 'from a sequencing request' do
    let(:eventful) { request }

    it 'includes the expected subjects' do
      expect(json.dig('event', 'subjects')).to match_unordered_json(
        [
          {
            'role_type' => 'flowcell',
            'subject_type' => 'flowcell',
            'uuid' => batch.uuid,
            'friendly_name' => batch.id
          },
          { 'role_type' => 'study', 'subject_type' => 'study', 'uuid' => study.uuid, 'friendly_name' => study.name },
          {
            'role_type' => 'sample',
            'subject_type' => 'sample',
            'uuid' => sample.uuid,
            'friendly_name' => sample.name
          },
          {
            'role_type' => 'sequencing_source_labware',
            'subject_type' => 'tube',
            'uuid' => stock_asset.uuid,
            'friendly_name' => stock_asset.human_barcode
          }
        ]
      )
    end
  end

  context 'from a non-sequencing batch' do
    let(:eventful) { create(:batch) }

    it 'includes the expected subjects' do
      expect(json.dig('event', 'subjects')).to match_unordered_json([])
    end
  end
end
