# frozen_string_literal: true
# At the end of the pulldown pipeline the wells of the final plate are transferred, individually,
# into MX library tubes.  Each well is effectively a pool of the stock wells, once they've been
# through the pipeline, so the mapping needs to be based on the original submissions.
class Transfer::FromPlateToTubeBySubmission < Transfer::BetweenPlateAndTubes
  after_create :build_asset_links

  private

  # Returns the MX library tube that the given well should be transferred into.
  def locate_mx_library_tube_for(well, _stock_wells)
    asset_cache[well.submission_ids.first]
  end

  # Memoised hash that maps a submission_id to the multiplexed labware created for that
  # submission. Entries are populated on first access, so each submission is looked up at
  # most once per transfer operation.
  # @return [Hash{Integer => Labware}]
  def asset_cache
    @asset_cache ||=
      Hash.new { |cache, submission_id| cache[submission_id] = Submission.find(submission_id).multiplexed_labware }
  end
end
