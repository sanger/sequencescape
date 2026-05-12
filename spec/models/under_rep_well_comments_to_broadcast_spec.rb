# frozen_string_literal: true

require 'rails_helper'

RSpec.describe UnderRepWellCommentsToBroadcast do
  let(:pcr_xp_plate)   { create(:plate_with_tagged_wells, sample_count: 5) }
  let(:well_a1)        { pcr_xp_plate.wells.located_at('A1').first }

  let(:poly_meta_underrep) { create(:poly_metadatum, key: 'under_represented', value: 'true') }
  let(:poly_meta_other)    { create(:poly_metadatum, key: 'other_key', value: 'some_value') }

  let(:poly_metadata_library_request) do
    create(:library_request,
           poly_metadata: [poly_meta_underrep, poly_meta_other],
           target_asset: well_a1)
  end

  let(:tube) do
    create(:multiplexed_library_tube, aliquots: pcr_xp_plate.aliquots.map(&:dup))
      .tap { |t| t.labware.parents << pcr_xp_plate }
  end

  let(:lane) do
    create(:lane, aliquots: tube.aliquots.map(&:dup)).tap do |l|
      l.labware.parents << tube
      l.index_aliquots
    end
  end

  let(:batch_request) { create(:sequencing_request, target_asset: lane, asset: tube.receptacle) }
  let(:batch)         { create(:batch).tap { |b| b.requests << batch_request } }

  before do
    well_a1.requests << poly_metadata_library_request
  end


  describe '#under_represented_well_comments' do
    context 'when a lane aliquot matches the well aliquot' do
      let(:comments) { batch.under_represented_well_comments }
      let(:comment)  { comments.first }

      it 'returns exactly one comment' do
        expect(comments.size).to eq(1)
      end

      it 'returns UnderRepWellComment objects' do
        expect(comment).to be_a(UnderRepWellCommentsToBroadcast::UnderRepWellComment)
      end

      it 'sets the correct batch_id' do
        expect(comment.batch_id).to eq(batch.id)
      end

      it 'sets the correct position from the batch request' do
        expect(comment.position).to eq(batch_request.position)
      end

      it 'sets the correct tag_index from the matching lane aliquot' do
        expected_tag_index = lane.aliquots
                                 .find { |a| a.sample_id == well_a1.aliquots.first.sample_id }
                               &.aliquot_index_value
        expect(comment.tag_index).to eq(expected_tag_index)
      end

      it 'associates the correct poly_metadatum' do
        expect(comment.poly_metadatum).to eq(poly_meta_underrep)
      end

      it 'does not include comments for non-under_represented metadata' do
        keys = comments.map { |c| c.poly_metadatum.key }
        expect(keys).to all(eq('under_represented'))
      end
    end

    context 'when no lane aliquot matches the well aliquot' do
      before do
        lane  # force eager creation before deleting indexes
        AliquotIndex.where(lane_id: lane.id).delete_all
        # Reload so lane.aliquots no longer carries aliquot_index_value
        lane.aliquots.each_with_index do |aliquot, i|
          aliquot.update!(tag_id: 9000+i, tag2_id: 8000+i)
        end
      end

      it 'returns an empty array' do
        expect(batch.under_represented_well_comments).to eq([])
      end
    end

    context 'when no requests have under_represented metadata' do
      let(:clean_batch_request) { create(:sequencing_request, target_asset: create(:lane)) }
      let(:clean_batch)         { create(:batch).tap { |b| b.requests << clean_batch_request } }

      it 'returns an empty array' do
        expect(clean_batch.under_represented_well_comments).to eq([])
      end
    end

  end

  # ─── UnderRepWellComment value object ───────────────────────────────────────
  describe UnderRepWellCommentsToBroadcast::UnderRepWellComment do
    subject(:comment) do
      described_class.new(
        poly_metadatum: poly_meta_underrep,
        batch_id:       batch.id,
        position:       batch_request.position,
        tag_index:      1
      )
    end

    it 'exposes batch_id' do
      expect(comment.batch_id).to eq(batch.id)
    end

    it 'exposes position' do
      expect(comment.position).to eq(batch_request.position)
    end

    it 'exposes tag_index' do
      expect(comment.tag_index).to eq(1)
    end

    it 'exposes poly_metadatum' do
      expect(comment.poly_metadatum).to eq(poly_meta_underrep)
    end

    it 'delegates key to poly_metadatum' do
      expect(comment.key).to eq(poly_meta_underrep.key)
    end

    it 'delegates value to poly_metadatum' do
      expect(comment.value).to eq(poly_meta_underrep.value)
    end

    it 'delegates updated_at to poly_metadatum' do
      expect(comment.updated_at).to eq(poly_meta_underrep.updated_at)
    end

    it 'delegates destroyed? to poly_metadatum' do
      expect(comment.destroyed?).to eq(poly_meta_underrep.destroyed?)
    end
  end
end