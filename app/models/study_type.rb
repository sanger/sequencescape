# frozen_string_literal: true

# On {Study} creation the user selects a {StudyType} from a drop down list
# of pre-registered study types.
#
# This information is exposed:
#
# - In the warehouses, where it *may* be used by customers, NPG, or bioinformaticians
# - Via the V1 API. (Not aware of any uses here, but there may be)
# - As <STUDY_TYPE existing_study_type="..." /> during study accessioning with the EBI
#
# @note {Study::Metadata.study_type_valid?} has hard-coded validation to prevent the 'Not specified' study type from
#       being used. This should probably be updated to use the {#valid_for_creation} flag. I'm also not sure of having
#       'Not specified' be a specific database entry, although it has been assigned to several historic studies so does
#       at least allow a not_nil constraint.
#
# @see DataReleaseStudyType
class StudyType < ApplicationRecord
  extend Attributable::Association::Target

  # @!attribute valid_for_creation
  #   @return [Boolean] Indicates a study can be created with this option (determines if it appears in the dropdown)
  # @!attribute vaild_type
  #   @return [Boolean] Indicates the study type is recognised by the EBI. If false the accessioned study will contain
  #                     <STUDY_TYPE existing_study_type="Other" new_study_type="<study_type.name>"/> instead of
  #                     <STUDY_TYPE existing_study_type="<study_type.name>"/>

  has_many :study

  validates :name,
            presence: true,
            uniqueness: { message: 'of study type already present in database', case_sensitive: false }

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
