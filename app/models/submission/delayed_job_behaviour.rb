module Submission::DelayedJobBehaviour
  def self.included(base)
    base.class_eval do
      conf_priority = configatron.delayed_job.submission_process_priority
      priority = conf_priority.present? ? conf_priority : 0
      handle_asynchronously :build_batch, :priority => priority
    end
  end

  def complete_building
    super
    build_batch
  end

  def build_batch
    finalize_build!
  rescue Quota::Error => quota_exception
    fail_set_message_and_save(quota_exception.message)
  rescue ActiveRecord::StatementInvalid => sql_exception
    # If an SQL problems occurs, it's more likely that's it's
    # a one shot one, e.g. timeout , deadlock etc ...
    # So we don't want the submission to fail but the delayed job to
    # retry later. Therefore the DelayedJob should fail
    raise sql_exception
  rescue => exception
    fail_set_message_and_save("#{exception.message}\n#{exception.backtrace.join("\n")}")
  end

  def finalize_build!
    self.process!
    self.ready!
  end

  def fail_set_message_and_save(message)
    self.fail!
    self.message = message
    self.save(false)        # Just in case the cause is it being invalid!
  end
  private :fail_set_message_and_save
end
