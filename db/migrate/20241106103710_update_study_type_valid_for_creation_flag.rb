# frozen_string_literal: true
# update 'Cancer Genomics' study type to be invalid for creation
class UpdateStudyTypeValidForCreationFlag < ActiveRecord::Migration[6.1]
  def up
    # Update specific study types by name
    StudyType.where(name: 'Cancer Genomics').update_all(valid_for_creation: false)
  end

  def down
    # define a way to reverse the changes when need to roll back
    StudyType.where(name: 'Cancer Genomics').update_all(valid_for_creation: true)
  end
end
