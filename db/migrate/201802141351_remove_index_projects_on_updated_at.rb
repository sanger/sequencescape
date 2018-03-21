# frozen_string_literal: true

# Auto generated migration to remove unused indexes
class RemoveIndexProjectsOnUpdatedAt < ActiveRecord::Migration[5.1]
  remove_index :projects, column: ['updated_at']
end
