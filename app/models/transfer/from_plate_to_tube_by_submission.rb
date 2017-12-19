# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2011,2012,2015 Genome Research Ltd.

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
    @asset_cache ||= Hash.new do |cache, submission_id|
      cache[submission_id] = Submission.find(submission_id).multiplexed_asset
    end
  end
end
