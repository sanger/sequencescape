# frozen_string_literal: true
class EventfulMailer < ActionMailer::Base # rubocop:todo Style/Documentation
  # rubocop:todo Metrics/ParameterLists
  def confirm_event(receiver, eventful, message, content, _milestone, sent_at = Time.zone.now)
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

  # rubocop:enable Metrics/ParameterLists

  def update_event(receiver, study, title, content, sent_at = Time.zone.now)
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

  # rubocop:todo Metrics/ParameterLists
  def confirm_sample_event(receiver, eventful, message, content, _milestone, sent_at = Time.zone.now)
    # rubocop:enable Metrics/ParameterLists
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

  def notify_request_fail(receiver, item, request, message, sent_at = Time.zone.now)
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

  def fail_attempt(receiver, request, sent_at = Time.zone.now)
    @request = request
    mail(
      from: (configatron.sequencescape_email).to_s,
      subject: "#{configatron.mail_prefix} Attempt fail for #{request.id}",
      bcc: receiver,
      sent_on: sent_at
    )
  end

  # rubocop:todo Metrics/ParameterLists
  def confirm_external_release_event(receiver, eventful, message, content, _milestone, sent_at = Time.zone.now)
    # rubocop:enable Metrics/ParameterLists
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
