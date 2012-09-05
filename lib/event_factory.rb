class EventFactory

  ###############################
  # Quota related notifications #
  ###############################
  # Creates an event and sends an email when a request for quota update is made
  def self.quota_update(project, user, incoming = {}, comment = "")
    content = "A change has been requested for this project's request quota:\n\n"

    incoming.each do |request_type_key, quota|
      request_type = RequestType.find_by_key(request_type_key.to_s)
      original_limit = project.quota_limit_for(request_type)

      if original_limit < quota.to_i
        content = content + "An increase in #{request_type.name.downcase} quota: from #{original_limit} to #{quota}.\n"
      elsif original_limit > quota.to_i
        content = content + "An decrease in #{request_type.name.downcase} quota: from #{original_limit} to #{quota}.\n"
      end
    end

    content = content + "\n"
    content = content + "Request received from: #{user.login}\n\n"
    content = content + "#{comment}\n\n"

    event = Event.new(
      :eventful_id   => project.id,
      :eventful_type => "Project",
      :message       => "Quota update request",
      :content       => content,
      :created_by    => user.login
    )
    event.save

    EventfulMailer.deliver_confirm_event(User.all_administrators_emails, event.eventful, event.message, event.content, "No Milestone")
    event
  end

  # Creates an event and sends an email when quota is updated
  def self.quota_updated(project, user)
    content = "Project quota approved by #{user.login}"

    event = Event.new(
      :eventful_id => project.id,
      :eventful_type => "Project",
      :message => "Project quota approved",
      :created_by => user.login,
      :content => content,
      :of_interest_to => "administrators"
    )
    event.save

    recipients = User.all_administrators_emails

    # Get the project owner's email
    unless project.owner.nil? || recipients.include?(project.owner.email)
      recipients << project.owner.email
    end

    # Delete empty strings
    recipients.delete_if {|x| x == ""}
    # Get rid of all duplicate email addresses
    recipients.uniq!

    EventfulMailer.deliver_confirm_event(recipients, event.eventful, event.message, event.content, "No Milestone")
  end

  #################################
  # project related notifications #
  #################################
  # Creates an event and sends an email when a new project is created
  def self.new_project(project, user)
    content = "Project registered by #{user.login}"

    event = Event.new(
      :eventful_id => project.id,
      :eventful_type => "Project",
      :message => "Project registered",
      :created_by => user.login,
      :content => content,
      :of_interest_to => "administrators"
    )
    event.save

    EventfulMailer.deliver_confirm_event(User.all_administrators_emails, event.eventful, event.message, event.content, "No Milestone")
  end

  # Creates an event and sends an email or emails when a project is approved
  def self.project_approved(project, user)
    content = "Project approved by #{user.login}"

    event = Event.new(
      :eventful_id => project.id,
      :eventful_type => "Project",
      :message => "Project approved",
      :created_by => user.login,
      :content => content,
      :of_interest_to => "administrators"
    )
    event.save

    recipients_email = []
    project_manager_email = ""
    unless project.manager.blank?
      project_manager_email = "#{project.manager.email}"
      recipients_email << project_manager_email
    end
    if user.is_administrator?
      administrators_email = User.all_administrators_emails
      administrators_email.each do |email|
        recipients_email << email unless email == project_manager_email
      end
    end
    recipients_email.each do |email|
      EventfulMailer.deliver_confirm_event(email, event.eventful, event.message, event.content, "No Milestone")
    end

  end

  ################################
  # Sample related notifications #
  ################################

  # Creates an event and sends an email when a new sample is created
  def self.new_sample(sample, project, user)
    content = "New '#{sample.name}' registered by #{user.login}"

    # Create Sample centric event
    sample_event = Event.create(
      :eventful_id => sample.id,
      :eventful_type => "Sample",
      :message => "Sample registered",
      :created_by => user.login,
      :content => content,
      :of_interest_to => "users"
    )

    recipients = User.all_administrators_emails

    if project.blank?
      EventfulMailer.deliver_confirm_sample_event(recipients, sample_event.eventful, sample_event.message, sample_event.content, "No Milestone")
    else
      # Create project centric event
      content = "New '#{sample.name}' registered by #{user.login}: #{sample.name}. This sample was assigned to the '#{project.name}' project."

      project_event = Event.create(
        :eventful_id => project.id,
        :eventful_type => "Project",
        :message => "Sample #{sample.name} registered",
        :created_by => user.login,
        :content => content,
        :of_interest_to => "administrators"
      )

      EventfulMailer.deliver_confirm_event(recipients, project_event.eventful, project_event.message, project_event.content, "No Milestone")
    end

    sample_event
  end

  def self.project_refund_request(project, user, reference)
    content = "Refund request by #{user.login}. Reference #{reference}"

    event = Event.new(
      :eventful_id => project.id,
      :eventful_type => "Project",
      :message => "Refund #{reference}",
      :created_by => user.login,
      :content => content,
      :of_interest_to => "administrators"
    )
    event.save

    #EventfulMailer.deliver_confirm_event(User.all_administrators_emails, event.eventful, event.message, event.content, "No Milestone")
  end

 ###############################
 # Study related notifications #
 ###############################

  # creates an event and sends an email when samples are register to a study
  def self.study_has_samples_registered(study,samples,user)
    sample_names_string = samples.map{|s| s.name}.join("','")
    content = "Samples '#{sample_names_string}' registered by user '#{user.login}' on #{Time.now}"

    study_event = Event.create(
      :eventful_id => study.id,
      :eventful_type => "Study",
      :message => "Sample(s) registered",
      :created_by => user.login,
      :content => content,
      :of_interest_to => "users"
    )

    recipients = []
    study.projects.each do |project|
      recipients << project.manager.email if project.manager
    end

    EventfulMailer.deliver_confirm_event(recipients, study_event.eventful, study_event.message, study_event.content, "No Milestone")
  end

  #################################
  # request related notifications #
  #################################

  # creates an event and sends an email when update(s) to a request fail
  def self.request_update_note_to_manager(request, user, message)
    content = "#{message}\nwhilst an attempt was made to update request #{request.id}\nby user '#{user.login}' on #{Time.now}"

    request_event = Event.create(
      :eventful_id => request.id,
      :eventful_type => "Request",
      :message => "Request update(s) failed",
      :created_by => user.login,
      :content => content,
      :of_interest_to => "manager"
    )

    recipients = []
    request.quotas.map(&:project).each do |project|
      recipients << project.manager.email if project && project.manager
    end

    EventfulMailer.deliver_confirm_event(recipients, request_event.eventful, request_event.message, request_event.content, "No Milestone")
  end

end
