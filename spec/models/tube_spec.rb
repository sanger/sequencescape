# frozen_string_literal: true

require 'rails_helper'
require 'timecop'

describe Tube do
  describe 'scope:: in_column_major_order' do
    let(:tube_rack) { create :tube_rack }
    let(:num_tubes) { locations.length }
    let(:locations) { %w[A01 H12 D04] }
    let(:barcodes) { Array.new(num_tubes) { create :fluidx } }

    before do
      Array.new(num_tubes) do |i|
        create(:sample_tube, :in_a_rack, tube_rack:, coordinate: locations[i], barcodes: [barcodes[i]])
      end
    end

    it 'sorts the racked tubes in column order' do
      expect(tube_rack.tubes.in_column_major_order.map(&:coordinate)).to eq(%w[A01 D04 H12])
    end
  end

  context 'when a tube is not in a rack' do
    let!(:tube) { create :tube }

    it 'returns nil for the tube_rack relation' do
      expect(tube.tube_rack).to be_nil
    end
  end

  context 'when a tube is in a rack' do
    let!(:tube_rack) { create :tube_rack }
    let!(:tube) { create :tube }
    let!(:racked_tube) { RackedTube.create(tube_rack_id: tube_rack.id, tube_id: tube.id) }

    it 'destroying the Tube destroys the RackedTube too, but not the TubeRack' do
      tube.receptacles.destroy_all
      tube.destroy

      expect(described_class.exists?(tube.id)).to be(false)
      expect(RackedTube.exists?(racked_tube.id)).to be(false)
      expect(TubeRack.exists?(tube_rack.id)).to be(true)
    end
  end

  describe '#scanned_in_date' do
    let(:scanned_in_asset) { create(:tube) }
    let(:unscanned_in_asset) { create(:tube) }

    before do
      create(
        :event,
        content: Time.zone.today.to_s,
        message: 'scanned in',
        family: 'scanned_into_lab',
        eventful: scanned_in_asset
      )
    end

    it 'returns a date if it has been scanned in' do
      expect(scanned_in_asset.scanned_in_date).to eq(Time.zone.today.to_s)
    end

    it "returns nothing if it hasn't been scanned in" do
      expect(unscanned_in_asset.scanned_in_date).to be_blank
    end
  end

  describe '#comments' do
    let(:tube) { create :tube }

    before { create :comment, commentable: tube, description: 'Comment on tube' }

    it 'allows comment addition' do
      tube.comments.create!(description: 'Works')
      comment = Comment.where(commentable: tube, description: 'Works')
      expect(comment.count).to eq(1)
    end

    context 'without requests' do
      it 'exposes its comments' do
        expect(tube.comments.length).to eq(1)
        expect(tube.comments.first.description).to eq('Comment on tube')
      end
    end

    context 'with requests' do
      let(:submission) { create :submission }
      let!(:request) { create :well_request, asset: tube, submission: }

      before do
        create :comment, commentable: request, description: 'Comment on request'
        tube.reload
      end

      it 'exposes its comments and those of the request' do
        expect(tube.comments.count).to eq(2)
        expect(tube.comments.map(&:description)).to include('Comment on tube')
        expect(tube.comments.map(&:description)).to include('Comment on request')
      end

      it 'allows comment addition' do
        tube.comments.create!(description: 'Works')
        comment = Comment.where(commentable: tube, description: 'Works')
        expect(comment.count).to eq(1)
        expect(request.reload.comments.count).to eq(2)
      end
    end

    context 'with requests in progress the wells' do
      before do
        submission = create :submission
        request = create(:well_request, submission:)
        tube.receptacle.aliquots << create(:aliquot, request:)
        create(:transfer_request, target_asset: tube, submission:)
        create :comment, commentable: request, description: 'Comment on request'
        tube.reload
      end

      it 'exposes its comments and those of the request' do
        expect(tube.comments.count).to eq(2)
        expect(tube.comments.map(&:description)).to include('Comment on tube')
        expect(tube.comments.map(&:description)).to include('Comment on request')
      end
    end

    context 'with multiple identical comments' do
      before do
        submission = create :submission
        request = create(:well_request, asset: tube, submission:)
        request2 = create(:well_request, asset: tube, submission:)
        create :comment, commentable: request, description: 'Duplicate comment'
        create :comment, commentable: request2, description: 'Duplicate comment'
        create :comment, commentable: tube, description: 'Duplicate comment'
        tube.reload
      end

      it 'de-duplicates repeat comments' do
        expect(tube.comments.count).to eq(2)
        expect(tube.comments.map(&:description)).to include('Comment on tube')
        expect(tube.comments.map(&:description)).to include('Duplicate comment')
      end
    end
  end
end
