class AddBulkTransfers < ActiveRecord::Migration
  def self.up
    ActiveRecord::Base.transaction do
      create_table :bulk_transfers do |t|
        t.timestamps
        t.references :user
      end
    end
  end

  def self.down
    drop_table :bulk_transfers
  end
end
