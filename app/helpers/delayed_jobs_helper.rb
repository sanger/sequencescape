# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2007-2011,2015 Genome Research Ltd.

module DelayedJobsHelper
  def job_type(job)
    if job.name =~ /StudyReport/
      'generate study report'
    elsif job.name =~ /Submission/
        'process submission '
    else
      job.name
    end
  end

  def job_status(job)
      if job.locked_by
        'In progress'
      elsif job.failed?
        'Failed'
      elsif job.last_error?
        'error'
      else
        'pending'
      end
  end
end
