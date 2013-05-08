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
