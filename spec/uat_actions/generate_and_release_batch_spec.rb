# frozen_string_literal: true

require 'rails_helper'

describe UatActions::GenerateAndReleaseBatch do
  let(:user) { UatActions::StaticRecords.user }
  let(:pipeline_name) { 'Ultima' }
  let(:pipeline_factory) { :ultima_sequencing_pipeline }
  let(:request_factory) { :ultima_sequencing_request }
  let(:pipeline) { create(pipeline_factory, name: pipeline_name) }
  let(:tube_one) { create(:library_tube) }
  let(:tube_two) { create(:library_tube) }
  let(:request_one) do
    create(request_factory, asset: tube_one, request_type: pipeline.request_types.first, state: 'pending')
  end
  let(:request_two) do
    create(request_factory, asset: tube_two, request_type: pipeline.request_types.first, state: 'pending')
  end
  let(:action) do
    described_class.new(
      tube_1_barcode: tube_one.human_barcode,
      tube_2_barcode: tube_two.human_barcode,
      pipeline_name: pipeline_name
    )
  end
  let(:released_batch) { Batch.find(action.report[:batch_id]) }

  before do
    request_one
    request_two
    allow(Pipeline).to receive(:find_by).and_call_original
    allow(Pipeline).to receive(:find_by).with(name: pipeline_name).and_return(pipeline)
    allow(pipeline).to receive(:completed_request_as_part_of_release_batch)
    allow(pipeline).to receive(:post_release_batch)
  end

  it 'keeps readiness validation enabled for normal batch creation', :aggregate_failures do
    normal_batch = pipeline.batches.build(requests: [request_one, request_two], user: user)
    expect(normal_batch).not_to be_valid
    expect(normal_batch.errors[:base]).to include('All requests must be ready to be added to a batch')
  end

  it 'creates and releases a batch', :aggregate_failures do
    expect(action.save).to be true
    expect(released_batch).to be_released
  end

  it 'includes the matching requests for both tubes' do
    action.save

    expect(released_batch.requests).to contain_exactly(request_one, request_two)
  end

  it 'runs the pipeline release callbacks', :aggregate_failures do
    action.save

    expect(pipeline).to have_received(:completed_request_as_part_of_release_batch).twice
    expect(pipeline).to have_received(:post_release_batch).with(released_batch, user)
  end

  context 'with the Ultima UG200 pipeline' do
    let(:pipeline_name) { 'Ultima UG200' }
    let(:pipeline_factory) { :ultima_ug200_sequencing_pipeline }
    let(:request_factory) { :ultima_ug200_sequencing_request }

    it 'creates and releases a batch containing the requests for the supplied tubes', :aggregate_failures do
      expect(action.save).to be true
      expect(released_batch).to be_released
    end
  end

  context 'when a tube barcode cannot be found' do
    let(:action) do
      described_class.new(
        tube_1_barcode: 'missing',
        tube_2_barcode: tube_two.human_barcode,
        pipeline_name: pipeline_name
      )
    end

    it 'does not create a batch and reports the missing tube', :aggregate_failures do
      expect(action.save).to be false
      expect(action.errors[:tube_1_barcode]).to include('could not be found')
      expect(Batch.count).to eq(0)
    end
  end

  context 'when a tube has no pending request in the selected pipeline' do
    let(:request_one) do
      create(request_factory, asset: tube_one, request_type: pipeline.request_types.first, state: 'passed')
    end

    it 'does not create a batch and reports the missing request', :aggregate_failures do
      expect(action.save).to be false
      expect(action.errors[:base]).to include('No pending request for Tube 1 was found in Ultima.')
      expect(Batch.count).to eq(0)
    end
  end
end
