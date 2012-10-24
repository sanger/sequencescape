class Project < ActiveRecord::Base
  include Api::ProjectIO::Extensions
  include ModelExtensions::Project

  cattr_reader :per_page
  @@per_page = 500
  include EventfulRecord
  include AASM
  include Uuid::Uuidable
  include Named
  extend EventfulRecord
  has_many_events
  has_many_lab_events

  aasm_column :state
  aasm_initial_state :pending
  aasm_state :pending
  aasm_state :active, :enter => :mark_active
  aasm_state :inactive, :enter => :mark_deactive

  aasm_event :reset do
    transitions :to => :pending, :from => [:inactive, :active]
  end

  aasm_event :activate do
    transitions :to => :active, :from => [:pending, :inactive]
  end

  aasm_event :deactivate do
    transitions :to => :inactive, :from => [:pending, :active]
  end

  has_many :quotas
  has_many :billing_events
  has_many :roles, :as => :authorizable
  has_many :orders
  has_many :studies, :class_name => "Study", :through => :orders, :source => :study, :uniq => true
  has_many :submissions, :through => :orders, :source => :submission, :uniq => true
  has_many :sample_manifests

  validates_presence_of :name
  validates_uniqueness_of :name, :on => :create, :message => "already in use (#{self.name})"

  named_scope :for_search_query, lambda { |query|
    { :conditions => [ 'name LIKE ? OR id=?', "%#{query}%", query ] }
  }


  def used_quota(request_type)
    quota_for(request_type).try(:used) || 0
  end

  def has_quota?(request_type, number)
    return true unless self.enforce_quotas?  # Quotas not being enforced so assume it does
    self.actionable? && (self.projected_remaining_quota(request_type) >= number)
  end

  def projected_remaining_quota(request_type)
    quota_for(request_type).try(:remaining) || 0
  end


  def quota_limit_for(request_type)
    quota_for(request_type).try(:limit) || 0
  end

  alias total_quota quota_limit_for

  def quota_for(request_type)
    request_type_id = request_type.is_a?(RequestType) ? request_type.id  : request_type
    self.quotas.find_by_request_type_id(request_type_id)
  end

  # create a quota if missing
  def quota_for!(request_type)
    quota = quota_for(request_type)
    quota || quotas.create(:request_type_id => request_type.is_a?(RequestType) ? request_type.id : request_type,
      :limit => 0,
      :preordered_count => 0)
  end

  def book_quota(request_type,number=1)
    quota_for!(request_type).book_request!(number, enforce_quotas?)
  end

  def unbook_quota(request_type, number=1)
    quota_for!(request_type).unbook_request!(number)
  end

  def use_quota!(request, unbook=true)
      quota_for!(request.request_type_id).add_request!(request, unbook, enforce_quotas?)
  end

  # Frees remaining quotas on the current project
  # Sets quota limit to the used quota level on each request type
  def quota_limit_equals_quota_used!
    self.quotas.each do |quota|
      quota.update_limit_to_used!
    end
  end

  def ended_billable_lanes(ended)
    events = []
    self.samples.each do |sample|
      if sample.ended.downcase == ended.downcase
        events << sample.billable_events
      end
    end
    events  = events.flatten
  end

  def billable_events
    e = []
    self.samples.each do |sample|
     e << sample.billable_events
    end
    e.flatten
  end

  def billable_events_between(from, to)
    a = []
    billable_events.each do |event|
      if event.created_at.to_date >= from and event.created_at.to_date <= to
        a << event
      end
    end
    a
  end

  def ended_billable_lanes_between(from, to, ended)
    events = ended_billable_lanes(ended)

    a = []
    events.each do |event|
      if event.created_at.to_date >= from and event.created_at.to_date <= to
        a << event
      end
    end
    a.size
  end

  def billable_lanes_between(from, to)
    billable_events_between(from, to).size
  end

  def new_quotas
    RequestType.all.each do |request_type|
      self.quotas.build(:limit => 0, :request_type => request_type)
    end
  end

  def new_quotas=(quotas=[])
    quotas.each do |k, v|
      request_type = RequestType.find(k) unless k.empty?
      self.quotas.build(:limit => v, :request_type => request_type)
    end
  end

  def compare_quotas(params_quotas)
    if params_quotas
      params_quotas.each do |key, limit|
        if quota = Quota.find_by_project_id_and_request_type_id(self.id, key)
          if quota.limit.to_i != limit.to_i
            return false
          end
        elsif limit.to_i > 0
          return false
        end
      end
    elsif self.quotas.size > 0
      return false
    else # self.quota.size == 0 && params_quotas == nil
      return true
    end # Quotas are identical
    true
  end

  def add_quotas(params_quotas)
    if params_quotas
      params_quotas.each do |key, limit|
        if quota = Quota.find_by_project_id_and_request_type_id(self.id, key)
          quota.limit = limit.to_i
          quota.save
        elsif limit.to_i > 0
          self.quotas << Quota.new(:limit => limit, :request_type_id => key)
        end
      end
    end
  end

  def set_available_quotas!(request_type, number)
    quota = quota_for!(request_type)
    quota.limit += number+quota.used
    quota.save!
  end

  def owners
    role = self.roles.detect{|r| r.name == "owner" }
    unless role.nil?
      role.users
    else
      []
    end
  end

  def owner
    owners_ = owners
    owners_ and owners_.first
  end

  def manager
    role = self.roles.detect{|r| r.name == "manager"}
    unless role.nil?
      role.users.first
    else
      nil
    end
  end

  def actionable?
    self.project_metadata.budget_division.name != 'Unallocated'
  end

  def sequencing_budget_division
    self.project_metadata.budget_division.name
  end

  PROJECT_FUNDING_MODELS = [
    '',
    "Internal",
    "External",
    "External - own machine"
  ]

  extend Metadata
  has_metadata do
    # NOTE: The following attribute is not required for Microarray Genotyping.
    # I think this might be broken and suggests that there should be separate classes for project: one for
    # next-gen sequencing that includes this attribute in it's metadata, and one for microarray genotyping
    # that doesn't.
    include ProjectManager::Associations
    include BudgetDivision::Associations

    attribute(:project_cost_code, :required => true)
    attribute(:funding_comments)
    attribute(:collaborators)
    attribute(:external_funding_source)
    attribute(:sequencing_budget_cost_centre)
    attribute(:project_funding_model, :in => PROJECT_FUNDING_MODELS)
    attribute(:gt_committee_tracking_id)

    before_validation do |record|
      record.project_funding_model = nil if record.project_funding_model.blank?
    end
  end

  named_scope :with_unallocated_budget_division, { :joins => :project_metadata, :conditions => { :project_metadata => { :budget_division_id => BudgetDivision.find_by_name('Unallocated') } } }
end
