# frozen_string_literal: true

require 'rails_helper'

describe Lane do
  it 'should find lanes that have requested aliquots' do
    aliquots = create_list(:aliquot, 5)
    requested_aliquots = [aliquots.pop, aliquots.pop]
    requested_aliquots_ids = requested_aliquots.map(&:id)

    # lane without requested aliquots
    lane = create :lane
    lane.aliquots << aliquots

    # lanes containing requested aliquots
    lane1 = create :lane
    lane2 = create :lane
    lane1.aliquots << requested_aliquots.first
    lane2.aliquots << requested_aliquots.last
    lanes_to_be_found = [lane1, lane2]

    expect(Lane.with_required_aliquots(requested_aliquots_ids)).to match_array(lanes_to_be_found)
  end

  it 'can be rebroadcasted' do
    lane = create :lane
    request = create :sequencing_request, target_asset: lane
    batch = create :sequencing_batch
    batch.requests << request
    # as requests_as_targets is a scope, not the above instance of batch receive the message
    expect(Batch.count).to eq 1
    expect_any_instance_of(Batch).to receive(:rebroadcast)
    lane.rebroadcast
  end
end
