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
    raise Quota::Error, self.errors.full_messages unless self.submittable?
  end
  private :check_project_details!

  def multiplier_for(request_type)
    return 1 if self.request_options.blank? or not self.request_options.key?(:multiplier)
    self.request_options[:multiplier][request_type.id.to_i] || 1
  end
  private :multiplier_for

  def checking_quotas?
    project.enforce_quotas? && @checking_quotas
  end
  private :checking_quotas?

  def submittable?
    @checking_quotas = true
    valid?
  ensure
    @checking_quotas = false
  end

  def quota_calculator(&block)
    Order.transaction do
      # If there are no assets then we do not need to check the quota as none will be used, regardless.
      return if assets.empty?

      # Not optimal but preserve the order of the request_types
      request_type_records = self.request_types.map { |rt_id|  RequestType.find(rt_id) }
      multiplexed          = request_type_records.detect(&:for_multiplexing?).present?

      request_type_records.each do |request_type|
        # If the user requires multiple runs of this request type then we need to count for that in the quota.
        # If we're not multiplexing in general, or for this individual request type, then we have to have enough
        # quote for all of the assets.  Otherwise they can be considered to be a single asset (i.e. a pool of them)
        quota_required  = multiplier_for(request_type)
        quota_required *= assets.size if not multiplexed
        yield(request_type, quota_required)
      end
    end
  end
  private :quota_calculator

  def book_quota_available_for_request_types!
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
end
