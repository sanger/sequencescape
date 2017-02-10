# This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2016 Genome Research Ltd.
class TransferRequest::InitialDownstream < TransferRequest
  def outer_request
    asset.requests.detect { |request| request.library_creation? && request.submission_id == submission_id }
  end
end
