class ProjectManager < ActiveRecord::Base 
  has_many :project
  
  validates_presence_of  :name
  validates_uniqueness_of :name, :message => "of project manager already present in database"
  
  def for_select_dropdown
    [self.name, self.id]
  end  

  module Associations
    def self.included(base)
      base.validates_presence_of :project_manager_id
      base.belongs_to :project_manager
    end
  end
end
