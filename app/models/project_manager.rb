class ProjectManager < ApplicationRecord
  extend Attributable::Association::Target

  def self.unallocated
    find_or_create_by!(name: 'Unallocated')
  end

  has_many :projects

  validates_presence_of :name
  validates_uniqueness_of :name, message: 'of project manager already present in database'

  module Associations
    def self.included(base)
      base.belongs_to :project_manager, optional: false
    end

    def project_manager
      super || ProjectManager.unallocated
    end
  end
end
