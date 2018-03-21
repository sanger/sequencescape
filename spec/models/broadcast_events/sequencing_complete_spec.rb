# frozen_string_literal: true

require 'rails_helper'

RSpec.describe BroadcastEvent::SequencingComplete, type: :model, broadcast_event: true do
  let(:user)  { create(:user) }
  let(:study) { create(:study) }
  let(:project) { create(:project) }
  let(:sample)  { create(:sample) }
  let(:aliquot) { create(:aliquot, study: study, project: project, sample: sample) }
  let(:pipeline) { create(:pipeline) }
  let(:submission) { create(:submission_without_order, priority: 3) }
  let(:request_type) { create(:sequencing_request_type, product_line: create(:product_line)) }
  let(:lane) { create(:lane) }
  let!(:request) do
    create(:sequencing_request_with_assets_and_ancestors,
           pipeline: pipeline,
           project: nil,
           study: nil,
           request_type: request_type,
           submission: submission,
           target_asset: lane,
           request_metadata_attributes: {
             fragment_size_required_from: 100,
             fragment_size_required_to: 200,
             read_length: 76
           })
  end
  let(:event) do
    BroadcastEvent::SequencingComplete.create!(seed: lane,
                                               user: user,
                                               properties: { result: :passed },
                                               created_at: Time.zone.parse('2018-01-12T13:37:03+00:00'))
  end
  let(:json)  { JSON.parse(event.to_json) }

  it 'has the correct event type' do
    expect(json['event']['event_type']).to eq('sequencing_complete')
  end

  it 'has a uuid' do
    expect(json['event']['uuid']).to_not be_empty
  end

  it 'has a date' do
    expect(json['event']['occured_at']).to eq('2018-01-12T13:37:03+00:00')
  end

  it 'has some metadata' do
    expect(json['event']['metadata']['read_length']).to eq(76)
    expect(json['event']['metadata']['pipeline']).to eq(request.pipeline.name)
    expect(json['event']['metadata']['team']).to eq(request_type.product_line.name)
  end

  it 'has the correct subjects' do
    lane.aliquots << aliquot
    subject_role_types = json['event']['subjects'].collect { |subject| subject['role_type'] }
    expect(subject_role_types).to include('sequencing_source_labware')
    expect(subject_role_types).to include('project')
    expect(subject_role_types).to include('study')
  end

  it 'can have a stock plate' do
    expect(json['event']['subjects'].collect { |subject| subject['role_type'] }).to include('stock_plate')
  end

  it 'can have library source labware' do
    allow(lane.source_labwares.first).to receive(:library_source_plates).and_return(create(:plate))
    expect(json['event']['subjects'].collect { |subject| subject['role_type'] }).to include('library_source_labware')
  end

  it 'has some samples' do
    allow(lane).to receive(:samples).and_return([create(:sample)])
    expect(json['event']['subjects'].collect { |subject| subject['role_type'] }).to include('sample')
  end

  it 'stores the result as metadata' do
    expect(json['event']['metadata']['result']).to eq('passed')
  end
end
