#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2007-2011,2011,2012,2015 Genome Research Ltd.
class CherrypickPipeline < CherrypickingPipeline
  include Pipeline::InboxGroupedBySubmission

  ALWAYS_SHOW_RELEASE_ACTIONS = true

  def post_finish_batch(batch, user)
    # Nothing, we don't want all the requests to be completed
  end

  def post_release_batch(batch, user)
    # stock wells
    batch.requests.each do |request|
      EventSender.send_pick_event(request.target_asset.id, request.target_asset.plate.purpose.name, "Pickup well #{request.asset.id}")
    end
    batch.release_pending_requests()
    batch.output_plates.each(&:cherrypick_completed)
  end

  def update_detached_request(batch, request)
    # We do not need to do any of the default behaviour:
    # 1. The requests should just be detached, not blocked
    # 2. The assets are not removed because they are not considered unused
  end
end
