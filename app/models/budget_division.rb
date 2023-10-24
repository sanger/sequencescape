# frozen_string_literal: true
# Property of {Project} set on {Project::Metadata}
# High level organisational area for funding
class BudgetDivision < ApplicationRecord
  extend Attributable::Association::Target

  def self.unallocated
    find_or_create_by!(name: 'Unallocated')
  end

  has_many :projects

  validates :name, presence: true
  validates :name, uniqueness: { message: 'of budget division already present in database', case_sensitive: false }

  module Associations
    def self.included(base)
      base.belongs_to :budget_division, optional: false
    end

    def budget_division
      # When this is called during initialisation of a Project, it is already set (therefore goes down 'super' route)
      # - due to the database-level default on projects table (budget_division_id = 1)
      super || BudgetDivision.unallocated
    end
  end
end
