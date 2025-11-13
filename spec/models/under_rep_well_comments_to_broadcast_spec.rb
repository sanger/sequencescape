# frozen_string_literal: true

require 'rails_helper'

RSpec.describe UnderRepWellCommentsToBroadcast do
  subject(:batch) { dummy_batch_class.new(id: 123, submissions: [submission]) }

  let(:dummy_batch_class) do
    Class.new do
      include UnderRepWellCommentsToBroadcast

      attr_accessor :id, :submissions

      def initialize(id:, submissions: [])
        @id = id
        @submissions = submissions
      end
    end
  end

  let(:poly_meta_underrep) { create(:poly_metadatum, key: 'under_represented', value: 'true') }
  let(:poly_meta_other)    { create(:poly_metadatum, key: 'other_key', value: 'some_value') }

  let(:tag)     { create(:tag, map_id: 1) }
  let(:aliquot) { create(:aliquot, tag:) }

  let(:lane_aliquot) { create(:aliquot) }
  let(:lane_source_request) { create(:request) }
  let(:batch_request) { create(:batch_request, request: lane_source_request, position: 1) }
  let(:lane) { create(:lane, aliquots: [lane_aliquot], source_request: lane_source_request) }
  let(:well_target_asset) { create(:well, aliquots: [aliquot]) }
  let(:well_asset)        { create(:well) }

  let(:request) do
    create(
      :library_request,
      poly_metadata: [poly_meta_underrep, poly_meta_other],
      target_asset: well_target_asset,
      asset: well_asset
    )
  end

  let(:submission) { create(:submission, requests: [request]) }

  before do
    lane_source_request.update!(batch_request:)
    AliquotIndexer.index(lane)
    allow(well_asset).to receive(:descendants).and_return([lane])
  end

  describe '#request_with_under_represented_wells' do
    it 'returns the request containing under_represented poly_metadata' do
      expect(batch.request_with_under_represented_wells).to contain_exactly(request)
    end

    it 'returns empty if no under_represented metadata exists' do
      allow(request).to receive(:poly_metadata).and_return([poly_meta_other])
      expect(batch.request_with_under_represented_wells).to be_empty
    end
  end

  describe '#under_represented_well_comments' do
    context 'when aliquot matches lane' do
      let(:comments) { batch.under_represented_well_comments }
      let(:comment)  { comments.first }

      it 'returns exactly one comment' do
        expect(comments.size).to eq(1)
      end

      it 'returns an UnderRepWellComment object' do
        expect(comment).to be_a(UnderRepWellCommentsToBroadcast::UnderRepWellComment)
      end

      it 'sets the correct batch_id' do
        expect(comment.batch_id).to eq(123)
      end

      it 'sets the correct tag_index' do
        expect(comment.tag_index).to eq(tag.map_id)
      end

      it 'sets the correct position' do
        expect(comment.position).to eq(lane.source_request.position)
      end

      it 'associates the correct poly_metadatum' do
        expect(comment.poly_metadatum).to eq(poly_meta_underrep)
      end
    end

    context 'when no aliquot matches the lane' do
      before { AliquotIndex.where(lane: lane, aliquot: lane_aliquot).delete_all }

      it 'returns an empty array' do
        expect(batch.under_represented_well_comments).to eq([])
      end
    end
  end

  describe '#comments' do
    it 'returns an array of comments' do
      expect(batch.comments).to be_an(Array)
    end
  end

  describe UnderRepWellCommentsToBroadcast::UnderRepWellComment do
    subject(:comment) do
      described_class.new(
        poly_metadatum: poly_meta_underrep,
        batch_id: 10,
        position: 2,
        tag_index: 5
      )
    end

    it 'exposes the batch_id' do
      expect(comment.batch_id).to eq(10)
    end

    it 'exposes the position' do
      expect(comment.position).to eq(2)
    end

    it 'exposes the tag_index' do
      expect(comment.tag_index).to eq(5)
    end

    it 'exposes the poly_metadatum' do
      expect(comment.poly_metadatum).to eq(poly_meta_underrep)
    end

    it 'delegates key to poly_metadatum' do
      expect(comment.key).to eq('under_represented')
    end

    it 'delegates value to poly_metadatum' do
      expect(comment.value).to eq('true')
    end

    it 'delegates updated_at to poly_metadatum' do
      expect(comment.updated_at).to eq(poly_meta_underrep.updated_at)
    end
  end
end
