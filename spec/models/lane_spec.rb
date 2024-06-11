# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Lane do
  let(:lane) { create(:lane_with_stock_plate) }
  let!(:request) { create(:sequencing_request_with_assets, target_asset: lane) }

  it 'finds lanes that have requested aliquots' do
    aliquots = create_list(:aliquot, 5)
    requested_aliquots = [aliquots.pop, aliquots.pop]
    requested_aliquots_ids = requested_aliquots.map(&:id)

    # lane without requested aliquots
    lane.aliquots << aliquots

    # lanes containing requested aliquots
    lane1 = create(:lane)
    lane2 = create(:lane)
    lane1.aliquots << requested_aliquots.first
    lane2.aliquots << requested_aliquots.last
    lanes_to_be_found = [lane1, lane2]

    expect(described_class.with_required_aliquots(requested_aliquots_ids)).to match_array(lanes_to_be_found)
  end

  it 'can be rebroadcasted' do
    # request = create :sequencing_request, target_asset: lane
    batch = create(:sequencing_batch)
    batch.requests << request

    # as requests_as_targets is a scope, not the above instance of batch receive the message
    expect(Batch.count).to eq 1
    expect_any_instance_of(Batch).to receive(:rebroadcast)
    lane.rebroadcast
  end

  it 'can have library source labware' do
    allow(lane.source_labwares.first).to receive(:library_source_plates).and_return(create(:plate))
  end

  it 'has some samples' do
    allow(lane).to receive(:samples).and_return([create(:sample)])
  end

  it 'has a friendly name matching with name' do
    expect(lane.friendly_name).to eq(lane.name)
  end
end
