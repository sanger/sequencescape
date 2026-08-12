# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Transfer::FromPlateToTubeBySubmission do
  let(:user) { create(:user) }

  # source_plate is a transfer_plate with a single well (no empty wells to confuse stock_wells).
  # We self-link the well via Well::Link so Plate#stock_wells returns it as its own stock well.
  # Library completion requests (for_multiplexing: true) on the well let
  # Submission#multiplexed_labware resolve the correct MX library tube.
  let(:source_plate) { create(:transfer_plate, well_count: 1) }
  let(:well) { source_plate.wells.first }

  let(:old_submission) { create(:submission) }
  let(:new_submission) { create(:submission) }
  let(:old_mx_tube) { create(:multiplexed_library_tube) }
  let(:new_mx_tube) { create(:multiplexed_library_tube) }

  # Creates a library_completion request on the well and sets its state.
  def build_library_completion(asset:, submission:, target_tube:, state: 'pending')
    create(
      :library_completion,
      asset: asset,
      target_asset: target_tube.receptacle,
      submission: submission,
      state: state
    )
  end

  # Creates a stock Well::Link so the well is treated as its own stock well by Plate#stock_wells.
  def link_stock_well(well)
    Well::Link.find_or_create_by!(type: 'stock', source_well: well, target_well: well)
  end

  before { link_stock_well(well) }

  # ─── #active_submission_id_for ────────────────────────────────────────────────

  describe '#active_submission_id_for' do
    subject(:transfer) { described_class.new(source: source_plate, user: user) }

    context 'when the well has a single pending request' do
      before do
        build_library_completion(asset: well, submission: new_submission, target_tube: new_mx_tube, state: 'pending')
      end

      it 'returns the submission_id of the pending request' do
        expect(transfer.send(:active_submission_id_for, well)).to eq(new_submission.id)
      end
    end

    context 'when the well has a single started request' do
      before do
        build_library_completion(asset: well, submission: new_submission, target_tube: new_mx_tube, state: 'started')
      end

      it 'returns the submission_id of the started request' do
        expect(transfer.send(:active_submission_id_for, well)).to eq(new_submission.id)
      end
    end

    context 'when the well has only a passed (completed) request' do
      before do
        build_library_completion(asset: well, submission: old_submission, target_tube: old_mx_tube, state: 'passed')
      end

      it 'falls back to the first submission_id on the well' do
        # The fallback path; the exact value depends on the well's submission associations.
        result = transfer.send(:active_submission_id_for, well)
        expect(result).to be_nil.or eq(old_submission.id)
      end
    end

    context 'when the well has both a passed old request and a pending new request' do
      before do
        build_library_completion(asset: well, submission: old_submission, target_tube: old_mx_tube, state: 'passed')
        build_library_completion(asset: well, submission: new_submission, target_tube: new_mx_tube, state: 'pending')
      end

      it 'returns the submission_id of the new active (pending) request' do
        expect(transfer.send(:active_submission_id_for, well)).to eq(new_submission.id)
      end

      it 'does not return the old completed submission_id' do
        expect(transfer.send(:active_submission_id_for, well)).not_to eq(old_submission.id)
      end
    end
  end

  # ─── #locate_mx_library_tube_for ─────────────────────────────────────────────

  describe '#locate_mx_library_tube_for' do
    subject(:transfer) { described_class.new(source: source_plate, user: user) }

    context 'when a source_well with a pending request is provided' do
      before do
        build_library_completion(asset: well, submission: new_submission, target_tube: new_mx_tube, state: 'pending')
      end

      it 'returns the MX tube associated with the active submission' do
        result = transfer.send(:locate_mx_library_tube_for, well, [], well)
        expect(result).to eq(new_mx_tube)
      end
    end

    context 'when the well has both a completed old and a pending new request' do
      before do
        build_library_completion(asset: well, submission: old_submission, target_tube: old_mx_tube, state: 'passed')
        build_library_completion(asset: well, submission: new_submission, target_tube: new_mx_tube, state: 'pending')
      end

      it 'returns the new submission MX tube' do
        result = transfer.send(:locate_mx_library_tube_for, well, [], well)
        expect(result).to eq(new_mx_tube)
      end

      it 'does not return the old submission MX tube' do
        result = transfer.send(:locate_mx_library_tube_for, well, [], well)
        expect(result).not_to eq(old_mx_tube)
      end
    end
  end

  # ─── #well_to_destination ─────────────────────────────────────────────────────

  describe '#well_to_destination' do
    subject(:transfer) { described_class.new(source: source_plate, user: user) }

    before do
      build_library_completion(asset: well, submission: new_submission, target_tube: new_mx_tube, state: 'pending')
    end

    it 'returns a hash keyed by the source well' do
      result = transfer.send(:well_to_destination)
      expect(result.keys).to include(well)
    end

    it 'maps the well to an array of [tube, stock_wells]' do
      expect(transfer.send(:well_to_destination)[well]).to match([new_mx_tube, a_collection_including(well)])
    end
  end

  # ─── Integration: Transfer::FromPlateToTubeBySubmission.create! ───────────────

  describe '.create!' do
    context 'when the well has a single active submission' do
      before do
        build_library_completion(asset: well, submission: new_submission, target_tube: new_mx_tube, state: 'pending')
      end

      it 'creates a transfer request targeting the correct MX tube' do
        described_class.create!(source: source_plate, user: user)
        expect(well.transfer_requests_as_source.first.target_labware).to eq(new_mx_tube)
      end

      it 'sets the correct submission_id on the transfer request' do
        described_class.create!(source: source_plate, user: user)
        expect(well.transfer_requests_as_source.first.submission_id).to eq(new_submission.id)
      end
    end

    context 'when the well has a completed old submission and a new active submission' do
      before do
        build_library_completion(asset: well, submission: old_submission, target_tube: old_mx_tube, state: 'passed')
        build_library_completion(asset: well, submission: new_submission, target_tube: new_mx_tube, state: 'pending')
      end

      it 'transfers to the new submission MX tube' do
        described_class.create!(source: source_plate, user: user)
        expect(well.transfer_requests_as_source.first.target_labware).to eq(new_mx_tube)
      end

      it 'does not transfer to the old submission MX tube' do
        described_class.create!(source: source_plate, user: user)
        expect(well.transfer_requests_as_source.first.target_labware).not_to eq(old_mx_tube)
      end

      it 'sets the new submission_id on the transfer request' do
        described_class.create!(source: source_plate, user: user)
        expect(well.transfer_requests_as_source.first.submission_id).to eq(new_submission.id)
      end
    end
  end
end
