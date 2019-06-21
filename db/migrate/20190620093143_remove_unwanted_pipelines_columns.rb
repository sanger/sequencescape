# frozen_string_literal: true

# These columns were either flagged for deletion, or mapped directly to
# the pipeline classes, and have been migrated to class attributes
# This is an attempt to reduce the complexity of the Pipeline inboxes
class RemoveUnwantedPipelinesColumns < ActiveRecord::Migration[5.1]
  def change
    remove_column :pipelines, :group_by_parent, :boolean
    remove_column :pipelines, :group_by_submission_to_delete, :boolean
    remove_column :pipelines, :group_by_study_to_delete, :boolean
  end
end
