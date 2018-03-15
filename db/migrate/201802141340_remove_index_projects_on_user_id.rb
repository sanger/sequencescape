# frozen_string_literal: true

# Auto generated migration to remove unused indexes
class RemoveIndexProjectsOnUserId < ActiveRecord::Migration[5.1]
  remove_index :studies, column: ['user_id']
end
