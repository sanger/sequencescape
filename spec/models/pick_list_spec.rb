# frozen_string_literal: true
require 'rails_helper'

RSpec.describe PickList, :pick_list do
  subject(:pick_list) { described_class.new(pick_attributes: picks, asynchronous: asynchronous) }

  let(:wells) { create_list(:untagged_well, 2) }
  let(:asynchronous) { false }
  let(:picks) { wells.map { |well| { source_receptacle: well } } }
  let(:project) { create(:project) }

  before do
    rt = create(:cherrypick_request_type, key: 'cherrypick')
    create(:cherrypick_pipeline, request_type: rt)
  end

  describe '#valid?' do
    # We want a simple interface, that doesn't demand any options that are not
    # strictly required.
    context 'with wells pre-populates with study and project' do
      it { is_expected.to be_valid }
    end

    context 'when wells lack project information' do
      let(:wells) { create_list(:untagged_well, 2, project: nil) }

      it { is_expected.not_to be_valid }
    end

    context 'when wells lack project information but the pick provides it' do
      let(:wells) { create_list(:untagged_well, 2, project: nil) }
      let(:picks) { wells.map { |well| { source_receptacle: well, project: project } } }

      it { is_expected.to be_valid }
    end
  end

  describe '#state' do
    before { pick_list.save }

    context 'when asynchronous is true' do
      let(:asynchronous) { true }

      it { expect(pick_list).to be_pending }
    end

    context 'when asynchronous is false' do
      let(:asynchronous) { false }

      it { expect(pick_list).to be_built }
    end
  end

  describe '.receptacles' do
    subject { pick_list.receptacles }

    context 'when asynchronous is true' do
      let(:asynchronous) { true }

      it { is_expected.to eq wells }
    end

    context 'when asynchronous is false' do
      let(:asynchronous) { false }

      it { is_expected.to eq wells }
    end
  end

  describe '#links' do
    subject { pick_list.links }

    before { pick_list.save }

    context 'when asynchronous is true' do
      let(:asynchronous) { true }

      it do
        expect(subject).to include(
          name: "Pick-list #{pick_list.id}",
          url: pick_list_url(pick_list, host: configatron.site_url)
        )
      end
    end

    context 'when asynchronous is false' do
      let(:asynchronous) { false }

      it do
        expect(subject).to include(
          name: "Batch #{Batch.last.id}",
          url: batch_url(Batch.last, host: configatron.site_url)
        )
      end
    end
  end

  describe '#create_batch!' do
    let(:pipeline) { create(:cherrypick_pipeline) }
    let(:user) { create(:user) }
    let(:submission) { create(:submission, user:) }
    let(:pick_list) { described_class.new(submission: submission, asynchronous: false) }

    # Create assets with specific barcodes to ensure consistent ordering
    let(:asset1) { create(:sample_tube, barcode: '111') }
    let(:asset2) { create(:sample_tube, barcode: '222') }
    let(:asset3) { create(:sample_tube, barcode: '333') }

    # Create requests with assets deliberately out of barcode order
    let(:request1) do
 create(:cherrypick_request, request_type: pipeline.request_types.first, asset: asset3, submission: submission) end
    let(:request2) do
 create(:cherrypick_request, request_type: pipeline.request_types.first, asset: asset1, submission: submission) end
    let(:request3) do
 create(:cherrypick_request, request_type: pipeline.request_types.first, asset: asset2, submission: submission) end

    before do
      allow(pick_list).to receive_messages(pipeline:, user:)
      submission.requests << [request1, request2, request3]
    end

    context 'when position is required by the pipeline' do
      before do
        allow(pipeline).to receive(:requires_position?).and_return(true)
      end

      it 'creates a batch with the correct requests' do
        pick_list.send(:create_batch!)

        batch = Batch.last
        expect(batch.requests).to contain_exactly(request1, request2, request3)
      end

      it 'sets positions on batch_requests based on asset.human_barcode order' do
        pick_list.send(:create_batch!)

        batch = Batch.last
        expect(batch.batch_requests.order(:position).pluck(:request_id)).to eq([request2.id, request3.id, request1.id])
      end
    end

    context 'when position is not required by the pipeline' do
      before do
        allow(pipeline).to receive(:requires_position?).and_return(false)
      end

      it 'creates a batch with the correct requests' do
        pick_list.send(:create_batch!)

        batch = Batch.last
        expect(batch.requests).to contain_exactly(request1, request2, request3)
      end

      it 'sets positions on batch_requests based on request order' do
        pick_list.send(:create_batch!)

        batch = Batch.last
        expect(batch.batch_requests.order(:position).pluck(:request_id)).to eq([request1.id, request2.id, request3.id])
      end
    end
  end
end
