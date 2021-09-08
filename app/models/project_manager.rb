# frozen_string_literal: true
class ProjectManager < ApplicationRecord # rubocop:todo Style/Documentation
  extend Attributable::Association::Target

  def self.unallocated
    find_or_create_by!(name: 'Unallocated')
  end

  has_many :projects

  validates :name, presence: true
  validates :name, uniqueness: { message: 'of project manager already present in database', case_sensitive: false }

  module Associations # rubocop:todo Style/Documentation
    def self.included(base)
      base.belongs_to :project_manager, optional: false
    end

    def project_manager
      super || ProjectManager.unallocated
    end
  end
end
