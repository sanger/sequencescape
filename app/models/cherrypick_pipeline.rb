# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2007-2011,2012,2015,2016 Genome Research Ltd.

class CherrypickPipeline < CherrypickingPipeline
  include Pipeline::InboxGroupedBySubmission

  ALWAYS_SHOW_RELEASE_ACTIONS = true

  def post_finish_batch(batch, user)
    # Nothing, we don't want all the requests to be completed
  end

  def post_release_batch(batch, _user)
    target_purpose = batch.output_plates.first.purpose.name
    # stock wells
    batch.requests.select { |r| r.passed? }.each do |request|
      request.asset.stock_wells.each do |stock|
        EventSender.send_pick_event(stock.id, target_purpose, "Pickup well #{request.asset.id}")
      end
    end
    batch.release_pending_requests
    batch.output_plates.each(&:cherrypick_completed)
  end

  def update_detached_request(batch, request)
    # We do not need to do any of the default behaviour:
    # 1. The requests should just be detached, not blocked
    # 2. The assets are not removed because they are not considered unused
  end
end
