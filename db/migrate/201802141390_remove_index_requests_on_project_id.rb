# frozen_string_literal: true

# Auto generated migration to remove unused indexes
class RemoveIndexRequestsOnProjectId < ActiveRecord::Migration[5.1]
  remove_index :requests, column: ['initial_project_id']
end
