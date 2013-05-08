class RenameQuotasTable < ActiveRecord::Migration
  def self.up
    ActiveRecord::Base.transaction do
      rename_table :quotas, :quotas_bkp
      rename_table :request_quotas, :request_quotas_bkp
    end
  end

  def self.down
    ActiveRecord::Base.transaction do
      rename_table :quotas_bkp, :quotas
      rename_table :request_quotas_bkp, :request_quotas
    end
  end
end
