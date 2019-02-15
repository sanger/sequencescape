class BudgetDivision < ApplicationRecord
  extend Attributable::Association::Target

  validates_presence_of :name
  has_many :project

  validates_presence_of :name
  validates_uniqueness_of :name, message: 'of budget division already present in database'

  module Associations
    def self.included(base)
      base.belongs_to :budget_division, optional: false
    end
  end
end
