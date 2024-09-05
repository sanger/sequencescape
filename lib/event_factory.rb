# frozen_string_literal: true
require 'eventful_mailer'
class EventFactory
  #################################
  # project related notifications #
  #################################

  # Creates an event when a new project is created
  # This used to send a notification using EventfulMailer, but it is no longer required
  def self.new_project(project, user)
    content = "Project registered by #{user.login}"

    event =
      Event.new(
        eventful_id: project.id,
        eventful_type: 'Project',
        message: 'Project registered',
        created_by: user.login,
        content: content,
        of_interest_to: 'administrators'
      )
    event.save
  end

  # Creates an event or emails when a project is approved
  # This used to send a notification using EventfulMailer, but it is no longer required
  def self.project_approved(project, user)
    content = "Project approved by #{user.login}"

    event =
      Event.new(
        eventful_id: project.id,
        eventful_type: 'Project',
        message: 'Project approved',
        created_by: user.login,
        content: content,
        of_interest_to: 'administrators'
      )
    event.save
  end

  def self.project_refund_request(project, user, reference)
    content = "Refund request by #{user.login}. Reference #{reference}"

    event =
      Event.new(
        eventful_id: project.id,
        eventful_type: 'Project',
        message: "Refund #{reference}",
        created_by: user.login,
        content: content,
        of_interest_to: 'administrators'
      )
    event.save
  end

  #################################
  # request related notifications #
  #################################

  # creates an event and sends an email when update(s) to a request fail
  # rubocop:todo Metrics/MethodLength
  def self.request_update_note_to_manager(request, user, message) # rubocop:todo Metrics/AbcSize
    content =
      # rubocop:todo Layout/LineLength
      "#{message}\nwhilst an attempt was made to update request #{request.id}\nby user '#{user.login}' on #{Time.zone.now}"

    # rubocop:enable Layout/LineLength

    request_event =
      Event.create(
        eventful_id: request.id,
        eventful_type: 'Request',
        message: 'Request update(s) failed',
        created_by: user.login,
        content: content,
        of_interest_to: 'manager'
      )

    recipients = []
    request.initial_project.tap { |project| recipients << project.manager.email if project && project.manager }

    EventfulMailer.confirm_event(
      recipients.reject(&:blank?),
      request_event.eventful,
      request_event.message,
      request_event.content,
      'No Milestone'
    ).deliver_now
  end
  # rubocop:enable Metrics/MethodLength

  # Creates an event for retention instructions when labware is updated
  def self.record_retention_instruction_updates(labware, user, old_retention_instruction)
    old_retention_instruction = 'nil' if old_retention_instruction.blank?
    Event.create!(
      eventful: labware,
      message: "Set retention instruction from #{old_retention_instruction} to #{labware.retention_instruction}",
      content: Time.zone.today.to_s,
      family: 'set_retention_instruction',
      created_by: user ? user.login : nil
    )
  end
end
