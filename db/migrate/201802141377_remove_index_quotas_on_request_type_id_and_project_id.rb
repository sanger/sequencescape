# frozen_string_literal: true

# Auto generated migration to remove unused indexes
class RemoveIndexQuotasOnRequestTypeIdAndProjectId < ActiveRecord::Migration[5.1]
  remove_index :quotas_bkp, column: %w[request_type_id project_id]
end
