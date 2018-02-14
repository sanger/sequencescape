# frozen_string_literal: true

# Auto generated migration to remove unused indexes
# Plus migration to drop the foreign keys, which only exist in
# production
class RemoveIndexRequestQuotasOnQuotaIdAndRequestId < ActiveRecord::Migration[5.1]
  foreign_keys(:request_quotas_bkp).each do |fk|
    remove_foreign_key :request_quotas_bkp, name: fk.options[:name]
  end
  remove_index :request_quotas_bkp, column: %w[quota_id request_id]
end
