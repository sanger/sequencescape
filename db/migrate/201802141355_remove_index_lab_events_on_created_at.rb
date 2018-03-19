# frozen_string_literal: true

# Auto generated migration to remove unused indexes
class RemoveIndexLabEventsOnCreatedAt < ActiveRecord::Migration[5.1]
  remove_index :lab_events, column: ['created_at']
end
