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
  rescue QuotaException => quota_exception
    fail_set_message_and_save(quota_exception.message)
  rescue => exception
    fail_set_message_and_save($!.to_yaml)
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
