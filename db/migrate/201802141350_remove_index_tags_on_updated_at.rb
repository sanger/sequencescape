# frozen_string_literal: true

# Auto generated migration to remove unused indexes
class RemoveIndexTagsOnUpdatedAt < ActiveRecord::Migration[5.1]
  remove_index :tags, column: ['updated_at']
end
