# frozen_string_literal: true

# Auto generated migration to remove unused indexes
class RemoveIndexBatchRequestsOnUpdatedAt < ActiveRecord::Migration[5.1]
  remove_index :batch_requests, column: ['updated_at']
end
