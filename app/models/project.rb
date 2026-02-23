# frozen_string_literal: true
require 'aasm'

# rubocop:disable Metrics/ClassLength
class Project < ApplicationRecord
  # It has to be here, as there are has_many through: :orders associations in modules
  has_many :orders
  include Api::ProjectIo::Extensions
  include Api::Messages::FlowcellIo::ProjectExtensions

  self.per_page = 500
  include EventfulRecord
  include AASM
  include Uuid::Uuidable
  include SharedBehaviour::Named
  include Role::Authorized
  extend EventfulRecord

  def self.states
    Project.aasm.states.map(&:name)
  end

  ACTIVE_STATE = 'active'
  has_many_events
  has_many_lab_events

  broadcast_with_warren

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

  scope :in_assets, ->(assets) { select('projects.*').uniq.joins(:aliquots).where(aliquots: { receptacle_id: assets }) }

  has_many :studies, -> { distinct }, class_name: 'Study', through: :orders, source: :study
  has_many :submissions, -> { distinct }, through: :orders, source: :submission
  has_many :sample_manifests
  has_many :aliquots

  has_many :owners, -> { where(roles: { name: 'owner' }) }, through: :roles, source: :users
  has_many :managers, -> { where(roles: { name: 'manager' }) }, through: :roles, source: :users

  validates :name, :state, presence: true
  validates :name, uniqueness: { on: :create, message: "already in use (#{name})", case_sensitive: false }

  scope :for_search_query,
        ->(query) do
          joins(project_metadata: :project).where(
            'projects.name LIKE ? OR projects.id = ? OR project_cost_code LIKE ?',
            "%#{query}%",
            query,
            "%#{query}%"
          )
        end

  # Allow us to pass in nil or '' if we don't want to filter state.
  # State is required so we don't need to look up an actual null state
  scope :in_state, ->(state) { state.present? ? where(state:) : all }

  scope :approved, -> { where(approved: true) }
  scope :unapproved, -> { where(approved: false) }
  scope :valid, -> { active.approved }
  scope :for_user, ->(user) { joins(roles: :user_role_bindings).where(roles_users: { user_id: user }) }

  scope :with_unallocated_manager,
        -> do
          roles = Role.arel_table
          joins(:roles).on(roles[:name].eq('manager')).where(roles[:id].eq(nil))
        end

  squishify :name

  def owner
    owners.first
  end

  def manager
    managers.first
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

  PROJECT_FUNDING_MODELS = ['', 'Internal', 'External', 'External - own machine'].freeze

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

  scope :with_unallocated_budget_division,
        -> do
          joins(:project_metadata).where(
            project_metadata: {
              budget_division_id: BudgetDivision.find_by(name: 'Unallocated')
            }
          )
        end
end
# rubocop:enable Metrics/ClassLength
