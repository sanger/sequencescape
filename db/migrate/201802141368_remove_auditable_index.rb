# frozen_string_literal: true

# Auto generated migration to remove unused indexes
class RemoveAuditableIndex < ActiveRecord::Migration[5.1]
  remove_index :audits, column: %w[auditable_id auditable_type]
end
