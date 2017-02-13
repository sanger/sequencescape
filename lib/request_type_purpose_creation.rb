# This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2015 Genome Research Ltd.
module RequestTypePurposeCreation
  def add_request_purpose
    purpose_key = request_class <= TransferRequest ? 'internal' : 'standard'
    self.request_purpose ||= RequestPurpose.find_by!(key: purpose_key)
    self
  end
end
