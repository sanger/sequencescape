# frozen_string_literal: true

require 'rails_helper'
require 'timecop'

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

    context 'with requests' do
      let(:submission) { create :submission }
      let!(:request) { create :well_request, asset: tube, submission: submission }

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

  context 'qc updates' do
    subject(:tube) { create :tube }

    describe '#update_from_qc' do
      let(:qc_result) { build :qc_result, key: key, value: value, units: units, assay_type: 'assay', assay_version: 1 }

      setup { tube.update_from_qc(qc_result) }
      context 'key: molarity with nM' do
        let(:key) { 'molarity' }
        let(:value) { 100 }

        context 'units: nM' do
          let(:units) { 'nM' }

          it 'works', :aggregate_failures do
            expect(tube.concentration).to eq(100)
          end
        end
      end

      context 'key: volume' do
        let(:key) { 'volume' }
        let(:units) { 'ul' }
        let(:value) { 100 }

        it { expect(tube.volume).to eq(100) }
      end

      context 'key: volume, units: ml' do
        let(:key) { 'volume' }
        let(:units) { 'ml' }
        let(:value) { 1 }

        it { expect(tube.volume).to eq(1000) }
      end
    end
  end
end
