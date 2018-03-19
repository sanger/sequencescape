# frozen_string_literal: true

# Auto generated migration to remove unused indexes
class RemoveIndexPermissionsOnPermissableId < ActiveRecord::Migration[5.1]
  remove_index :permissions, column: ['permissable_id']
end
