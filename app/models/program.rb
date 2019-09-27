class Program < ApplicationRecord
  extend Attributable::Association::Target

  default_scope ->() { order(:name) }

  validates :name,
            presence: true,
            uniqueness: { message: 'of programs already present in database', case_sensitive: false }

  has_many :study_metadata, class_name: 'Study::Metadata'
  has_many :studies, through: :study_metadata

  module Associations
    def self.included(base)
      base.validates_presence_of :program_id
      base.belongs_to :program
    end
  end
end
