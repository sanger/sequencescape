# frozen_string_literal: true

require 'rails_helper'

RSpec.describe BroadcastEvent::PoolReleased, :broadcast_event do
  let(:source_plate) do
    pl = create(:full_stock_plate)
    pl.wells.first.aliquots << create(:aliquot, sample: tube.samples.first)
    pl.wells.last.aliquots << create(:aliquot, sample: tube.samples.last)
    tube.ancestors << pl
    pl
  end
  let(:tube) { create(:multiplexed_library_tube, sample_count: 2, purpose: create(:illumina_htp_mx_tube_purpose)) }

  let(:submission) { create(:library_submission) }
  let(:order) { submission.orders.first }
  let(:request1) do
    create(
      :multiplex_request,
      asset: source_plate.wells.first,
      target_asset: tube.receptacle,
      state: 'passed',
      order: order
    )
  end
  let(:request2) do
    create(
      :multiplex_request,
      asset: source_plate.wells.last,
      target_asset: tube.receptacle,
      state: 'passed',
      order: order
    )
  end
  let(:library_request) { create(:library_request, target_asset: source_plate.wells.first) }

  let(:event) { described_class.create!(seed: tube, user: create(:user), properties: { order_id: order.id }) }
  let(:subject_hash) { event.as_json['event'][:subjects].group_by(&:role_type) }
  let(:metadata) { event.as_json['event'][:metadata] }

  before do
    request1
    request2
    library_request
  end

  it 'generates a json' do
    expect(event.to_json).not_to be_nil
  end

  describe 'subjects' do
    it 'has an order' do
      expect(subject_hash['order'].count).to eq(1)
    end

    it 'has a study' do
      expect(subject_hash['study'].count).to eq(1)
    end

    it 'has a project' do
      expect(subject_hash['project'].count).to eq(1)
    end

    it 'has a submission' do
      expect(subject_hash['submission'].count).to eq(1)
    end

    it 'has a library_source_labware' do
      expect(subject_hash['library_source_labware'].count).to eq(1)
    end

    it 'has a multiplexed_library' do
      expect(subject_hash['multiplexed_library'].count).to eq(1)
    end

    it 'has a stock_plate' do
      expect(subject_hash['stock_plate'].count).to eq(1)
    end

    it 'has 2 samples' do
      expect(subject_hash['sample'].count).to eq(2)
    end
  end

  describe 'metadata' do
    it 'has a library_type' do
      expect(metadata['library_type']).not_to be_nil
    end

    it 'has a fragment_size_from' do
      expect(metadata['fragment_size_from']).not_to be_nil
    end

    it 'has a fragment_size_to' do
      expect(metadata['fragment_size_to']).not_to be_nil
    end

    it 'has a bait_library' do
      expect(metadata['bait_library']).not_to be_nil
    end

    it 'has a order_type' do
      expect(metadata['order_type']).not_to be_nil
      expect(metadata['order_type']).not_to eq('UNKNOWN')
    end

    it 'has a submission_template' do
      expect(metadata['submission_template']).not_to be_nil
    end

    it 'has a team' do
      expect(metadata['team']).not_to be_nil
      expect(metadata['team']).not_to eq('UNKNOWN')
    end
  end
end
