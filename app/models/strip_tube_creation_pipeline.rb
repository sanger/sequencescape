# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2014,2015 Genome Research Ltd.

class StripTubeCreationPipeline < Pipeline
  self.inbox_partial = 'group_by_parent'
  self.purpose_information = false
end
