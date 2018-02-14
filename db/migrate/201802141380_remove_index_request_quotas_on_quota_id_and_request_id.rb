# frozen_string_literal: true

# Auto generated migration to remove unused indexes
class RemoveIndexRequestQuotasOnQuotaIdAndRequestId < ActiveRecord::Migration[5.1]
  remove_index :request_quotas_bkp, column: %w[quota_id request_id]
end
