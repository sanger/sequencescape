class StudyType < ApplicationRecord
  extend Attributable::Association::Target

  has_many :study

  validates_presence_of :name
  validates_uniqueness_of :name, message: 'of study type already present in database'

  scope :for_selection, ->() { order(:name).where(valid_for_creation: true) }

  def self.include?(studytype_name)
    study_type = StudyType.find_by(name: studytype_name)
    unless study_type.nil?
      return study_type.valid_type
    end

    false
  end

  module Associations
    def self.included(base)
      base.validates_presence_of :study_type_id
      base.belongs_to :study_type
    end
  end
end
