class EventfulMailer < ActionMailer::Base
  def confirm_event(receiver, eventful, message, content, milestone, sent_at = Time.now)
    from        "#{configatron.sequencescape_email}"
    subject     "#{configatron.mail_prefix} #{eventful.class} #{eventful.id}: #{message}"
    bcc         receiver
    body        :eventful => eventful, :message => message, :content => content
    sent_on     sent_at
  end

  def update_event(receiver, study, title, content, sent_at = Time.now)
    from        "#{configatron.sequencescape_email}"
    subject     "#{configatron.mail_prefix}  Study #{study.id}: #{title}"
    bcc         receiver
    body        :study => study, :message => title, :content => content
    sent_on     sent_at
  end

  def confirm_sample_event(receiver, eventful, message, content, milestone, sent_at = Time.now)
    from        "#{configatron.sequencescape_email}"
    subject     "#{configatron.mail_prefix} #{eventful.class} #{eventful.id}: #{message}"
    bcc         receiver
    body        :eventful => eventful, :message => message, :content => content
    sent_on     sent_at
  end

  def notify_overrun(receiver, eventful, message, run, lane, sent_at = Time.now)
    from        "#{configatron.sequencescape_email}"
    subject     "#{configatron.mail_prefix} Sequencing overrun for item #{eventful.id}"
    bcc         receiver
    body        :eventful => eventful, :message => message, :run => run, :lane => lane
    sent_on     sent_at
  end

  def notify_request_fail(receiver, item, request, message, sent_at = Time.now)
    from        "#{configatron.sequencescape_email}"
    subject     "#{configatron.mail_prefix} Request failure for item #{item.id}"
    bcc         receiver
    body        :item => item, :request => request, :message => message
    sent_on     sent_at
  end

  def fail_attempt(receiver, request, sent_at = Time.now)
    from        "#{configatron.sequencescape_email}"
    subject     "#{configatron.mail_prefix} Attempt fail for #{request.id}"
    bcc         receiver
    body        :request => request
    sent_on     sent_at
  end

  def confirm_external_release_event(receiver, eventful, message, content, milestone, sent_at = Time.now)
    from        "#{configatron.sequencescape_email}"
    subject     "#{configatron.mail_prefix} #{eventful.class} #{eventful.id}: #{message}"
    bcc         receiver
    body        :eventful => eventful, :message => message, :content => content
    sent_on     sent_at
  end
end
