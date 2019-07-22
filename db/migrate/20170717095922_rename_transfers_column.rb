# Rails migration
class RenameTransfersColumn < ActiveRecord::Migration[5.1]
  def change
    rename_column :transfers, :transfers, :transfers_hash
  end
end
