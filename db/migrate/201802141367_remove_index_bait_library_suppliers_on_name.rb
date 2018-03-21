# frozen_string_literal: true

# Auto generated migration to remove unused indexes
class RemoveIndexBaitLibrarySuppliersOnName < ActiveRecord::Migration[5.1]
  remove_index :bait_library_suppliers, column: ['name']
end
