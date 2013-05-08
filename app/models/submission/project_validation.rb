module Submission::ProjectValidation
  def self.included(base)
    base.class_eval do
      # We probably want to move this validation
      validates_each(:project, :if => :checking_project?) do |record, attr, project|
        record.errors.add_to_base("Project #{project.name} is not approved")                 unless project.approved?
        record.errors.add_to_base("Project #{project.name} is not active")                   unless project.active?
        record.errors.add_to_base("Project #{project.name} does not have a budget division") unless project.actionable?
      end
    end
  end

  def complete_building
    check_project_details!
    super
  end

  def checking_project?
    project && project.enforce_quotas? && @checking_project
  end

  Error = Class.new(Exception)

  def check_project_details!
    raise Submission::ProjectValidation::Error, self.errors.full_messages.join("\n") unless self.submittable?
  end
  private :check_project_details!

  def multiplier_for(request_type)
    return 1 if self.request_options.blank? or not self.request_options.key?(:multiplier)
    self.request_options[:multiplier][request_type.id.to_i] || 1
  end
  private :multiplier_for

  def submittable?
    begin
      @checking_project = true
      valid?
    ensure
      @checking_project = false
    end
  end

  # Hack to be able to build order
  # from pulled data
  def save_after_unmarshalling
    @saving_without_validation=true
    save_without_validation
    @saving_without_validation=false
  end

end
