# frozen_string_literal: true

require 'rails_helper'
require 'shared_contexts/limber_shared_context'

describe Plate do
  describe '#comments' do
    let(:plate) { create :plate, well_count: 2 }

    before { create :comment, commentable: plate, description: 'Comment on plate' }

    it 'allows comment addition' do
      plate.comments.create!(description: 'Works')
      comment = Comment.where(commentable: plate, description: 'Works')
      expect(comment.count).to eq(1)
    end

    context 'without requests' do
      it 'exposes its comments' do
        expect(plate.comments.length).to eq(1)
        expect(plate.comments.first.description).to eq('Comment on plate')
      end
    end

    context 'with requests out of the wells' do
      before do
        submission = create :submission
        request = create :well_request, asset: plate.wells.first, submission: submission
        create :comment, commentable: request, description: 'Comment on request'
        plate.reload
      end

      it 'exposes its comments and those of the request' do
        expect(plate.comments.count).to eq(2)
        expect(plate.comments.map(&:description)).to include('Comment on plate')
        expect(plate.comments.map(&:description)).to include('Comment on request')
      end

      it 'allows comment addition' do
        plate.comments.create!(description: 'Works')
        comment = Comment.where(commentable: plate, description: 'Works')
        expect(comment.count).to eq(1)
      end
    end

    context 'with requests in progress the wells' do
      before do
        submission = create :submission
        request = create :well_request, submission: submission
        plate.wells.first.aliquots << create(:aliquot, request: request)
        create :transfer_request, target_asset: plate.wells.first, submission: submission
        create :comment, commentable: request, description: 'Comment on request'
        plate.reload
      end

      it 'exposes its comments and those of the request' do
        expect(plate.comments.count).to eq(2)
        expect(plate.comments.map(&:description)).to include('Comment on plate')
        expect(plate.comments.map(&:description)).to include('Comment on request')
      end
    end

    context 'with multiple identical comments' do
      before do
        submission = create :submission
        request = create :well_request, asset: plate.wells.first, submission: submission
        request2 = create :well_request, asset: plate.wells.last, submission: submission
        create :comment, commentable: request, description: 'Duplicate comment'
        create :comment, commentable: request2, description: 'Duplicate comment'
        create :comment, commentable: plate, description: 'Duplicate comment'
        plate.reload
      end

      it 'de-duplicates repeat comments' do
        expect(plate.comments.count).to eq(2)
        expect(plate.comments.map(&:description)).to include('Comment on plate')
        expect(plate.comments.map(&:description)).to include('Duplicate comment')
      end
    end
  end

  context 'barcodes' do
    # Maintaining existing barcode behaviour
    context 'sanger barcodes' do
      let(:plate) { create :plate  }

      describe '#human_barcode' do
        subject { plate.human_barcode }

        it { is_expected.to eq 'SQPD-1' }
      end

      # On the sequencescape22 barcode format we dont support ean13
      describe '#ean13_barcode' do
        subject(:plate_barcode) { plate.ean13_barcode }

        it { 
          expect(plate_barcode).to be_nil 
        }
      end
    end
  end

  # Pools are horrendously complicated

  describe '#pools' do
    include_context 'a limber target plate with submissions'

    subject { target_plate.pools }

    context 'before passing' do
      let(:expected_pools_hash) do
        {
          target_submission.uuid => {
            wells: %w[A1 B1 C1],
            insert_size: {
              from: 1,
              to: 20
            },
            library_type: {
              name: 'Standard'
            },
            request_type: library_request_type.key,
            pcr_cycles: nil,
            pool_complete: false,
            for_multiplexing: false
          }
        }
      end

      it { is_expected.to eq expected_pools_hash }
    end

    context 'after passing' do
      before { WorkCompletion.create!(user: create(:user), target: target_plate, submissions: [target_submission]) }

      context 'with downstream requests' do
        let(:expected_pools_hash) do
          {
            target_submission.uuid => {
              wells: %w[A1 B1 C1],
              request_type: multiplex_request_type.key,
              pool_complete: false,
              for_multiplexing: true
            }
          }
        end

        it { is_expected.to eq expected_pools_hash }
      end

      describe 'input_plate#pools' do
        subject { input_plate.pools }

        let(:expected_pools_hash) do
          {
            target_submission.uuid => {
              wells: %w[A1 B1 C1],
              insert_size: {
                from: 1,
                to: 20
              },
              library_type: {
                name: 'Standard'
              },
              request_type: library_request_type.key,
              pcr_cycles: nil,
              pool_complete: true,
              for_multiplexing: false
            },
            decoy_submission.uuid => {
              wells: %w[A1 B1 C1],
              insert_size: {
                from: 1,
                to: 20
              },
              library_type: {
                name: 'Standard'
              },
              request_type: library_request_type.key,
              pcr_cycles: nil,
              pool_complete: false,
              for_multiplexing: false
            }
          }
        end

        it { is_expected.to eq expected_pools_hash }
      end

      context 'without downstream requests' do
        let(:submission_request_types) { [library_request_type] }
        let(:expected_pools_hash) { {} }

        it { is_expected.to eq expected_pools_hash }
      end
    end
  end
end
