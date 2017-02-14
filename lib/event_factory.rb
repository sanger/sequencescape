# This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2007-2011,2011,2013,2015 Genome Research Ltd.
require 'eventful_mailer'
class EventFactory
  #################################
  # project related notifications #
  #################################
  # Creates an event and sends an email when a new project is created
  def self.new_project(project, user)
    content = "Project registered by #{user.login}"

    event = Event.new(
      eventful_id: project.id,
      eventful_type: 'Project',
      message: 'Project registered',
      created_by: user.login,
      content: content,
      of_interest_to: 'administrators'
    )
    event.save

    admin_emails = User.all_administrators_emails.reject(&:blank?)

    EventfulMailer.confirm_event(
      admin_emails,
      event.eventful,
      event.message,
      event.content,
      'No Milestone'
    ).deliver_now unless admin_emails.empty?
  end

  # Creates an event and sends an email or emails when a project is approved
  def self.project_approved(project, user)
    content = "Project approved by #{user.login}"

    event = Event.new(
      eventful_id: project.id,
      eventful_type: 'Project',
      message: 'Project approved',
      created_by: user.login,
      content: content,
      of_interest_to: 'administrators'
    )
    event.save

    recipients_email = []
    project_manager_email = ''
    unless project.manager.blank?
      project_manager_email = (project.manager.email).to_s
      recipients_email << project_manager_email
    end
    if user.is_administrator?
      administrators_email = User.all_administrators_emails
      administrators_email.each do |email|
        recipients_email << email unless email == project_manager_email
      end
    end

    EventfulMailer.confirm_event(recipients_email, event.eventful, event.message, event.content, 'No Milestone').deliver_now
  end

  def self.project_refund_request(project, user, reference)
    content = "Refund request by #{user.login}. Reference #{reference}"

    event = Event.new(
      eventful_id: project.id,
      eventful_type: 'Project',
      message: "Refund #{reference}",
      created_by: user.login,
      content: content,
      of_interest_to: 'administrators'
    )
    event.save

    # EventfulMailer.deliver_confirm_event(User.all_administrators_emails, event.eventful, event.message, event.content, "No Milestone")
  end

  ###############################
  # Study related notifications #
  ###############################

  # creates an event and sends an email when samples are register to a study
  def self.study_has_samples_registered(study, samples, user)
    sample_names_string = samples.map { |s| s.name }.join("','")
    content = "Samples '#{sample_names_string}' registered by user '#{user.login}' on #{Time.now}"

    study_event = Event.create(
      eventful_id: study.id,
      eventful_type: 'Study',
      message: 'Sample(s) registered',
      created_by: user.login,
      content: content,
      of_interest_to: 'users'
    )

    recipients = []
    study.projects.each do |project|
      recipients << project.manager.email if project.manager
    end

    EventfulMailer.confirm_event(recipients.reject(&:blank?), study_event.eventful, study_event.message, study_event.content, 'No Milestone').deliver_now
  end

  #################################
  # request related notifications #
  #################################

  # creates an event and sends an email when update(s) to a request fail
  def self.request_update_note_to_manager(request, user, message)
    content = "#{message}\nwhilst an attempt was made to update request #{request.id}\nby user '#{user.login}' on #{Time.now}"

    request_event = Event.create(
      eventful_id: request.id,
      eventful_type: 'Request',
      message: 'Request update(s) failed',
      created_by: user.login,
      content: content,
      of_interest_to: 'manager'
    )

    recipients = []
    request.initial_project.tap do |project|
      recipients << project.manager.email if project && project.manager
    end

    EventfulMailer.confirm_event(recipients.reject(&:blank?), request_event.eventful, request_event.message, request_event.content, 'No Milestone').deliver_now
  end
end
