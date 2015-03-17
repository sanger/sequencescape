#This file is part of SEQUENCESCAPE; it is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2015 Genome Research Ltd.
##
# Set on a multiplexed request_type
# Pools based on the submission.
module RequestType::PoolingMethod::Submission
  def pool_count
    1
  end

  def pool_index_for_asset(_)
    0
  end

  def pool_index_for_request(_)
    0
  end
end
