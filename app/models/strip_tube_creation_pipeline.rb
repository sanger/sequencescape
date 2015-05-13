#This file is part of SEQUENCESCAPE; it is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2015 Genome Research Ltd.
class StripTubeCreationPipeline < Pipeline

  INBOX_PARTIAL = 'group_by_parent'

  def inbox_partial
    INBOX_PARTIAL
  end

  def purpose_information?
    false
  end

end
