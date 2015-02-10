#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2007-2011 Genome Research Ltd.
class PulldownLibraryCreationPipeline < LibraryCreationPipeline
  def pulldown?
    true
  end

  def prints_a_worksheet_per_task?
    true
  end
end
