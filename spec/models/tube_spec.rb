# frozen_string_literal: true

require 'rails_helper'

describe Tube, type: :model do
  describe '#comments' do
    let(:tube) { create :tube }

    before do
      create :comment, commentable: tube, description: 'Comment on tube'
    end

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

    context 'with requests out of the wells' do
      before do
        submission = create :submission
        request = create :well_request, asset: tube, submission: submission
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
      end
    end

    context 'with requests in progress the wells' do
      before do
        submission = create :submission
        request = create :well_request, submission: submission
        tube.aliquots << create(:aliquot, request: request)
        create :transfer_request, target_asset: tube, submission: submission
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
        request = create :well_request, asset: tube, submission: submission
        request2 = create :well_request, asset: tube, submission: submission
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
