# frozen_string_literal: true
class AddDataReleasePreventionOtherCommentToStudyMetadata < ActiveRecord::Migration[7.0]
  def change
    add_column :study_metadata, :data_release_prevention_other_comment, :string, default: nil
  end
end
