module Submission::QuotaBehaviour
  def self.included(base)
    base.class_eval do
      validates_each(:project, :if => :checking_quotas?) do |record, attr, project|
        record.errors.add_to_base('Quotas are being enforced but have not been setup')       if     project.quotas.all.empty? || project.quotas.map(&:limit).all?(&:zero?)
        record.errors.add_to_base("Project #{project.name} is not approved")                 unless project.approved?
        record.errors.add_to_base("Project #{project.name} is not active")                   unless project.active?
        record.errors.add_to_base("Project #{project.name} does not have a budget division") unless project.actionable?
      end

      delegate :book_quota, :unbook_quota, :quota_for!, :to => :project
      after_create :book_quota_available_for_request_types!
    end
  end

  #after_create :book_quota_available_for_request_types!

  def complete_building
    check_project_details!
    super
  end

  def check_project_details!
    raise Quota::Error, self.errors.full_messages.join("\n") unless self.submittable?
  end
  private :check_project_details!

  def multiplier_for(request_type)
    return 1 if self.request_options.blank? or not self.request_options.key?(:multiplier)
    self.request_options[:multiplier][request_type.id.to_i] || 1
  end
  private :multiplier_for

  def checking_quotas?
    project && project.enforce_quotas? && @checking_quotas
  end
  private :checking_quotas?


  def submittable?
    @checking_quotas = true
    valid?
  ensure
    @checking_quotas = false
  end

  def quota_calculator(&block)
    raise NotImplementedError if self.respond_to?(:build_request_graph!)
  end
  private :quota_calculator


  # Hack to be able to build order
  # from pulled data
  def save_after_unmarshalling
      @saving_without_validation=true
      save_without_validation
      @saving_without_validation=false
  end

  def book_quota_available_for_request_types!
    return if @saving_without_validation
    check_project_details!
    quota_calculator(&method(:book_quota))
  end
  private :book_quota_available_for_request_types!

  def unbook_quota_available_for_request_types!
    check_project_details!
    quota_calculator(&method(:unbook_quota))
  end

  def use_quota!(request, unbook=true)
    return unless project
    project.use_quota!(request, unbook)
  end

  # can that be put as a hook ?
  def before_destroy
    # We need to unbook preordered quota
    # but not if it's already been done'

    unbook_quota_available_for_request_types! unless submission && submission.state == "failed"
  end
end
