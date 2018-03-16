# frozen_string_literal: true

# Auto generated migration to remove unused indexes
class RemoveIndexRequestsOnUpdatedAt < ActiveRecord::Migration[5.1]
  remove_index :requests, column: ['updated_at']
end
