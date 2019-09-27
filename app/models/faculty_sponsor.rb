class FacultySponsor < ApplicationRecord
  include SharedBehaviour::Named
  extend Attributable::Association::Target

  default_scope { order(:name) }

  validates :name,
            presence: true,
            uniqueness: { message: 'of faculty sponsor already present in database', case_sensitive: false }

  has_many :study_metadata, class_name: 'Study::Metadata'
  has_many :studies, through: :study_metadata

  def count_studies
    studies.count
  end

  module Associations
    def self.included(base)
      base.validates_presence_of :faculty_sponsor
      base.belongs_to :faculty_sponsor
    end
  end
end
