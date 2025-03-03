# frozen_string_literal: true

# This module provides helper methods for handling studies within UAT actions.
# If a study_name is provided, it will validate that the study exists. If no
# study_name is provided, it will use the default study.
#
# @example Including the StudyHelper module
#   class SomeUatActionClass
#     include UatActions::StudyHelper
#   end
module UatActions::StudyHelper
  ERROR_STUDY_DOES_NOT_EXIST = 'Study %s does not exist.'

  def self.included(base)
    base.class_eval { validate :validate_study_exists }
  end

  private

  # Returns the study if study_name is specified, otherwise returns the default
  # study. It assumes that if the study_name is specified, the study is already
  # validated.
  #
  # @return [Study] the Study object
  def study
    @study ||=
      if study_name.present?
        Study.find_by!(name: study_name) # already validated
      else
        UatActions::StaticRecords.study # default study
      end
  end

  # Validates that the study exists for the specified study_name. Empty
  # study_name is considered valid because the default study is used in that
  # case.
  #
  # @return [void]
  def validate_study_exists
    return if study_name.blank?
    return if Study.exists?(name: study_name)

    message = format(UatActions::GeneratePlates::ERROR_STUDY_DOES_NOT_EXIST, study_name)
    errors.add(:study_name, message)
  end
end
