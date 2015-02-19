#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2007-2011,2012 Genome Research Ltd.
class QcPipeline < Pipeline
  INBOX_PARTIAL='show_qc'

  def inbox_partial
    INBOX_PARTIAL
  end

  def qc?
    true
  end
end
