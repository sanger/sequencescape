# frozen_string_literal: true

# Auto generated migration to remove unused indexes
class RemoveIndexStudyReportsOnUpdatedAt < ActiveRecord::Migration[5.1]
  remove_index :study_reports, column: ['updated_at']
end
