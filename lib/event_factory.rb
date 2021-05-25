require 'eventful_mailer'
class EventFactory # rubocop:todo Style/Documentation
  #################################
  # project related notifications #
  #################################

  # Creates an event when a new project is created
  # This used to send a notification using EventfulMailer, but it is no longer required
  def self.new_project(project, user) # rubocop:todo Metrics/MethodLength
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
  def self.project_approved(project, user) # rubocop:todo Metrics/MethodLength
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

  def self.project_refund_request(project, user, reference) # rubocop:todo Metrics/MethodLength
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

    # EventfulMailer.deliver_confirm_event(User.all_administrators_emails, event.eventful, event.message, event.content, "No Milestone")
  end

  #################################
  # request related notifications #
  #################################

  # creates an event and sends an email when update(s) to a request fail
  # rubocop:todo Metrics/MethodLength
  def self.request_update_note_to_manager(request, user, message) # rubocop:todo Metrics/AbcSize
    content =
      "#{message}\nwhilst an attempt was made to update request #{request.id}\nby user '#{user.login}' on #{Time.zone.now}"

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
end
