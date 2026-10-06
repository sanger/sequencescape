# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Transfer::FromPlateToTubeBySubmission do
  let(:user) { create(:user) }

  # source_plate is a transfer_plate with a single well (no empty wells to confuse stock_wells).
  # We self-link the well via Well::Link so Plate#stock_wells returns it as its own stock well.
  # An incoming transfer request associates the well with a submission. Its library completion
  # request lets Submission#multiplexed_labware resolve the correct MX library tube.
  let(:source_plate) { create(:transfer_plate, well_count: 1) }
  let(:well) { source_plate.wells.first }

  let(:submission) { create(:submission) }
  let(:mx_tube) { create(:multiplexed_library_tube) }

  # Creates a library_completion request on the well and sets its state.
  def build_library_completion(asset:, submission:, target_tube:, state: 'pending')
    create(:transfer_request_with_submission, target_asset: asset, submission: submission)
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

  # ─── #locate_mx_library_tube_for ─────────────────────────────────────────────

  describe '#locate_mx_library_tube_for' do
    subject(:transfer) { described_class.new(source: source_plate, user: user) }

    context 'when a source well has an incoming transfer request' do
      before do
        build_library_completion(asset: well, submission: submission, target_tube: mx_tube)
      end

      it 'returns the MX tube associated with the well submission' do
        result = transfer.send(:locate_mx_library_tube_for, well, [])
        expect(result).to eq(mx_tube)
      end
    end
  end

  # ─── #well_to_destination ─────────────────────────────────────────────────────

  describe '#well_to_destination' do
    subject(:transfer) { described_class.new(source: source_plate, user: user) }

    before do
      build_library_completion(asset: well, submission: submission, target_tube: mx_tube)
    end

    it 'returns a hash keyed by the source well' do
      result = transfer.send(:well_to_destination)
      expect(result.keys).to include(well)
    end

    it 'maps the well to an array of [tube, stock_wells]' do
      expect(transfer.send(:well_to_destination)[well]).to match([mx_tube, a_collection_including(well)])
    end
  end

  # ─── Integration: Transfer::FromPlateToTubeBySubmission.create! ───────────────

  describe '.create!' do
    context 'when the well has a submission' do
      before do
        build_library_completion(asset: well, submission: submission, target_tube: mx_tube)
      end

      it 'creates a transfer request targeting the correct MX tube' do
        described_class.create!(source: source_plate, user: user)
        expect(well.transfer_requests_as_source.first.target_labware).to eq(mx_tube)
      end

      it 'sets the correct submission_id on the transfer request' do
        described_class.create!(source: source_plate, user: user)
        expect(well.transfer_requests_as_source.first.submission_id).to eq(submission.id)
      end
    end
  end
end
