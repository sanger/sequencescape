# frozen_string_literal: true

# Auto generated migration to remove unused indexes
class RemoveIndexSubmissionsOnState < ActiveRecord::Migration[5.1]
  remove_index :orders, column: ['state_to_delete']
end
