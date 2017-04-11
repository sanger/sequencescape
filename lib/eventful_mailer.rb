# This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2007-2011,2012,2015 Genome Research Ltd.
class EventfulMailer < ActionMailer::Base
  def confirm_event(receiver, eventful, message, content, _milestone, sent_at = Time.now)
    @eventful = eventful
    @message = message
    @content = content
    mail(
      from: (configatron.sequencescape_email).to_s,
      subject: "#{configatron.mail_prefix} #{eventful.class} #{eventful.id}: #{message}",
      bcc: receiver,
      sent_on: sent_at
    )
  end

  def update_event(receiver, study, title, content, sent_at = Time.now)
    @study = study
    @message = title
    @content = content
    mail(
      from: (configatron.sequencescape_email).to_s,
      subject: "#{configatron.mail_prefix}  Study #{study.id}: #{title}",
      bcc: receiver,
      sent_on: sent_at
    )
  end

  def confirm_sample_event(receiver, eventful, message, content, _milestone, sent_at = Time.now)
    @eventful = eventful
    @message = message
    @content = content
    mail(
      from: (configatron.sequencescape_email).to_s,
      subject: "#{configatron.mail_prefix} #{eventful.class} #{eventful.id}: #{message}",
      bcc: receiver,
      sent_on: sent_at
    )
  end

  def notify_request_fail(receiver, item, request, message, sent_at = Time.now)
    @item = item
    @request = request
    @message = message
    mail(
      from: (configatron.sequencescape_email).to_s,
      subject: "#{configatron.mail_prefix} Request failure for item #{item.id}",
      bcc: receiver,
      sent_on: sent_at
    )
  end

  def fail_attempt(receiver, request, sent_at = Time.now)
    @request = request
    mail(
      from: (configatron.sequencescape_email).to_s,
      subject: "#{configatron.mail_prefix} Attempt fail for #{request.id}",
      bcc: receiver,
      sent_on: sent_at
    )
  end

  def confirm_external_release_event(receiver, eventful, message, content, _milestone, sent_at = Time.now)
    @eventful = eventful
    @message = message
    @content = content
    mail(
      from: (configatron.sequencescape_email).to_s,
      subject: "#{configatron.mail_prefix} #{eventful.class} #{eventful.id}: #{message}",
      bcc: receiver,
      sent_on: sent_at
    )
  end
end
