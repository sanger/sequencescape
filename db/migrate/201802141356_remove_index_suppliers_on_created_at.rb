# frozen_string_literal: true

# Auto generated migration to remove unused indexes
class RemoveIndexSuppliersOnCreatedAt < ActiveRecord::Migration[5.1]
  remove_index :suppliers, column: ['created_at']
end
