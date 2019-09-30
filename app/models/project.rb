require 'aasm'

class Project < ApplicationRecord
  # It has to be here, as there are has_many through: :orders associations in modules
  has_many :orders
  include Api::ProjectIO::Extensions
  include ModelExtensions::Project
  include Api::Messages::FlowcellIO::ProjectExtensions

  self.per_page = 500
  include EventfulRecord
  include AASM
  include Uuid::Uuidable
  include SharedBehaviour::Named
  extend EventfulRecord

  def self.states
    Project.aasm.states.map(&:name)
  end

  ACTIVE_STATE = 'active'.freeze
  has_many_events
  has_many_lab_events

  broadcast_via_warren

  aasm column: :state, whiny_persistence: true do
    state :pending, initial: true
    state :active
    state :inactive

    event :reset do
      transitions to: :pending, from: %i[inactive active]
    end

    event :activate do
      transitions to: :active, from: %i[pending inactive]
    end

    event :deactivate do
      transitions to: :inactive, from: %i[pending active]
    end
  end

  scope :in_assets, ->(assets) {
    select('projects.*').uniq
                        .joins(:aliquots)
                        .where(aliquots: { receptacle_id: assets })
  }

  has_many :roles, as: :authorizable
  has_many :studies, ->() { distinct }, class_name: 'Study', through: :orders, source: :study
  has_many :submissions,  ->() { distinct }, through: :orders, source: :submission
  has_many :sample_manifests
  has_many :aliquots

  validates :name, :state, presence: true
  validates :name, uniqueness: { on: :create, message: "already in use (#{name})", case_sensitive: false }

  scope :for_search_query, ->(query) {
    where(['name LIKE ? OR id=?', "%#{query}%", query])
  }

  # Allow us to pass in nil or '' if we don't want to filter state.
  # State is required so we don't need to look up an actual null state
  scope :in_state, ->(state) {
    state.present? ? where(state: state) : all
  }

  scope :approved,     ->()     { where(approved: true) }
  scope :unapproved,   ->()     { where(approved: false) }
  scope :valid,        ->()     { active.approved }
  scope :for_user,     ->(user) { joins(roles: :user_role_bindings).where(roles_users: { user_id: user }) }

  scope :with_unallocated_manager, ->() {
    roles = Role.arel_table
    joins(:roles).on(roles[:name].eq('manager')).where(roles[:id].eq(nil))
  }

  squishify :name

  def owners
    role = roles.detect { |r| r.name == 'owner' }
    if role.nil?
      []
    else
      role.users
    end
  end

  def owner
    owners_ = owners
    owners_ and owners_.first
  end

  def manager
    role = roles.detect { |r| r.name == 'manager' }
    if role.nil?
      nil
    else
      role.users.first
    end
  end

  def actionable?
    project_metadata.budget_division.name != 'Unallocated'
  end

  def submittable?
    return true if project_metadata.project_funding_model.present?

    errors.add(:base, 'No funding model specified')
    false
  end

  def r_and_d?
    project_metadata.budget_division.name == configatron.r_and_d_division
  end

  def sequencing_budget_division
    project_metadata.budget_division.name
  end

  alias_attribute :friendly_name, :name

  delegate :project_cost_code, to: :project_metadata

  PROJECT_FUNDING_MODELS = [
    '',
    'Internal',
    'External',
    'External - own machine'
  ].freeze

  extend Metadata
  # @!parse class Project::Metadata < Metadata::Base; end
  has_metadata do
    # NOTE: The following attribute is not required for Microarray Genotyping.
    # I think this might be broken and suggests that there should be separate classes for project: one for
    # next-gen sequencing that includes this attribute in it's metadata, and one for microarray genotyping
    # that doesn't.
    include ProjectManager::Associations
    include BudgetDivision::Associations

    custom_attribute(:project_cost_code, required: true)
    custom_attribute(:funding_comments)
    custom_attribute(:collaborators)
    custom_attribute(:external_funding_source)
    custom_attribute(:sequencing_budget_cost_centre)
    custom_attribute(:project_funding_model, in: PROJECT_FUNDING_MODELS)
    custom_attribute(:gt_committee_tracking_id)

    before_validation do |record|
      record.project_cost_code = nil if record.project_cost_code.blank?
      record.project_funding_model = nil if record.project_funding_model.blank?
    end
  end

  def subject_type
    'project'
  end

  scope :with_unallocated_budget_division, -> { joins(:project_metadata).where(project_metadata: { budget_division_id: BudgetDivision.find_by(name: 'Unallocated') }) }
end
