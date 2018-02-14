# frozen_string_literal: true

# Auto generated migration to remove unused indexes
class RemoveIndexAuditsOnCreatedAt < ActiveRecord::Migration[5.1]
  remove_index :audits, column: ['created_at']
end
