# frozen_string_literal: true

# Auto generated migration to remove unused indexes
class RemoveIndexSuppliersOnUpdatedAt < ActiveRecord::Migration[5.1]
  remove_index :suppliers, column: ['updated_at']
end
