# frozen_string_literal: true

# Auto generated migration to remove unused indexes
class RemoveIndexStudyReportsOnCreatedAt < ActiveRecord::Migration[5.1]
  remove_index :study_reports, column: ['created_at']
end
