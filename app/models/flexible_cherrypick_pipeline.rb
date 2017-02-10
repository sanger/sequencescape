# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2015 Genome Research Ltd.

class FlexibleCherrypickPipeline < CherrypickForPulldownPipeline
  def post_finish_batch(batch, _user)
    batch.requests.with_target.each(&:pass!)
  end
end
