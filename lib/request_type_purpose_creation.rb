# This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2015 Genome Research Ltd.
module RequestTypePurposeCreation
  def add_request_purpose
    self.request_purpose = :standard
    self
  end
end
