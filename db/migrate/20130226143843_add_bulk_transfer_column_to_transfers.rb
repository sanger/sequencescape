class AddBulkTransferColumnToTransfers < ActiveRecord::Migration
  def self.up
    ActiveRecord::Base.transaction do
      add_column :transfers, :bulk_transfer_id, :integer
    end
  end

  def self.down
    ActiveRecord::Base.transaction do
      remove_column :transfers, :bulk_transfer_id
    end
  end
end
