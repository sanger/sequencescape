# frozen_string_literal: true

# Auto generated migration to remove unused indexes
class RemoveIndexPlatePurposesOnUpdatedAt < ActiveRecord::Migration[5.1]
  remove_index :plate_purposes, column: ['updated_at']
end
