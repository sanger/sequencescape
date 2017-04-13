# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2013,2015 Genome Research Ltd.

class CherrypickForFluidigmRequest < CherrypickRequest
  has_metadata as: Request do
    belongs_to :target_purpose, class_name: 'Purpose'
    association(:target_purpose, :name)
    validates_presence_of :target_purpose
  end

  delegate :target_purpose, to: :request_metadata
end
