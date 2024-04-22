# frozen_string_literal: true
module Submission::DelayedJobBehaviour
  def default_priority
    configatron.delayed_job.fetch(:submission_process_priority, 0)
  end

  def queue_submission_builder
    # Lower priorities get processed faster. This ensures high priority submissions get processed first.
    Delayed::Job.enqueue SubmissionBuilderJob.new(id), priority: default_priority - priority
  end

    def build_batch # rubocop:todo Metrics/AbcSize
    ActiveRecord::Base.transaction { finalize_build! }
  rescue ActiveRecord::StatementInvalid => e
    # If an SQL problems occurs, it's more likely that's it's
    # a one shot one, e.g. timeout , deadlock etc ...
    # So we don't want the submission to fail but the delayed job to
    # retry later. Therefore the DelayedJob should fail
    raise e
  rescue ActiveRecord::RecordInvalid, Submission::ProjectValidation::Error => e
    Rails.logger.error(e.message)
    Rails.logger.error(e.backtrace)
    fail_set_message_and_save(e.message)
  rescue StandardError => e
    Rails.logger.error(e.message)
    Rails.logger.error(e.backtrace)
    fail_set_message_and_save("#{e.message}\n#{e.backtrace.join("\n")}")
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
