# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2007-2011,2012,2013,2014,2015 Genome Research Ltd.

module Submission::DelayedJobBehaviour
  def default_priority
    configatron.delayed_job.fetch(:submission_process_priority, 0)
  end

  def complete_building
    super
    # Lower priorities get processed faster. This ensures high priority submissions get processed first.
    Delayed::Job.enqueue SubmissionBuilderJob.new(id), priority: default_priority - priority
  end

  def build_batch
    ActiveRecord::Base.transaction do
      finalize_build!
    end
  rescue Submission::ProjectValidation::Error => project_exception
    fail_set_message_and_save(project_exception.message)
  rescue ActiveRecord::StatementInvalid => sql_exception
    # If an SQL problems occurs, it's more likely that's it's
    # a one shot one, e.g. timeout , deadlock etc ...
    # So we don't want the submission to fail but the delayed job to
    # retry later. Therefore the DelayedJob should fail
    raise sql_exception
  rescue ActiveRecord::RecordInvalid => exception
    fail_set_message_and_save(exception.message)
  rescue => exception
    fail_set_message_and_save("#{exception.message}\n#{exception.backtrace.join("\n")}")
  end

  def finalize_build!
    process!
    ready!
  end

  def fail_set_message_and_save(message)
    fail!
    self.message = message[0..254]
    save(validate: false) # Just in case the cause is it being invalid!
  end
  private :fail_set_message_and_save
end
