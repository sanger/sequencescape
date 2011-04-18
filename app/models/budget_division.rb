class BudgetDivision < ActiveRecord::Base 
  validates_presence_of  :name
  has_many :project

  validates_presence_of  :name
  validates_uniqueness_of :name, :message => "of budget division already present in database"

  acts_as_audited :on => [:destroy, :update]

  def for_select_dropdown
    [self.name, self.id]
  end  

  module Associations
    def self.included(base)
      base.validates_presence_of :budget_division_id
      base.belongs_to :budget_division
    end
  end
end
