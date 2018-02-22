# frozen_string_literal: true

# Auto generated migration to remove unused indexes
class RemoveIndexQuotasOnUpdatedAt < ActiveRecord::Migration[5.1]
  remove_index :quotas_bkp, column: ['updated_at']
end
