# frozen_string_literal: true
# At the end of the pulldown pipeline the wells of the final plate are transferred, individually,
# into MX library tubes.  Each well is effectively a pool of the stock wells, once they've been
# through the pipeline, so the mapping needs to be based on the original submissions.
class Transfer::FromPlateToTubeBySubmission < Transfer::BetweenPlateAndTubes
  after_create :build_asset_links

  private

  def locate_mx_library_tube_for(well, _stock_wells)
    asset_cache[well.submission_ids.first]
  end

  #
  # The asset cache saves the asset for each submission, ensuring we only need
  # to look it up once.
  #
  # @return [Asset] The asset into which the well should be transferred
  #
  def asset_cache
    @asset_cache ||=
      Hash.new { |cache, submission_id| cache[submission_id] = Submission.find(submission_id).multiplexed_labware }
  end
end
