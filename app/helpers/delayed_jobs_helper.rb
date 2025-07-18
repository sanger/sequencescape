# frozen_string_literal: true
module DelayedJobsHelper
  def job_last_error(job)
    # split last error by new line and return the first line
    job.last_error&.split("\n")&.first || ''
  end

  def job_type(job)
    case job.name
    when /StudyReport/
      'generate study report'
    when /Submission/
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
