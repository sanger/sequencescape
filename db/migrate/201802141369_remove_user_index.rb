# frozen_string_literal: true

# Auto generated migration to remove unused indexes
class RemoveUserIndex < ActiveRecord::Migration[5.1]
  remove_index :audits, column: %w[user_id user_type]
end
