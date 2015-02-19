#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2011,2012 Genome Research Ltd.
# At the end of the pulldown pipeline the wells of the final plate are transferred, individually,
# into MX library tubes.  Each well is effectively a pool of the stock wells, once they've been
# through the pipeline, so the mapping needs to be based on the original submissions.
class Transfer::FromPlateToTubeBySubmission < Transfer::BetweenPlateAndTubes
  def locate_mx_library_tube_for(well, stock_wells)
    return nil if stock_wells.empty?
    current_submission = well.creation_request.submission_id
    stock_wells.first.requests_as_source.detect do |request|
      request.submission_id == current_submission && request.target_asset.is_a?(Tube)
    end.try(:target_asset)
  end
  private :locate_mx_library_tube_for

end
