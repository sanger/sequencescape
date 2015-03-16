class ChangeTransfersFieldTransfersLength < ActiveRecord::Migration
  def self.up
    change_column :transfers, :transfers, :text
  end

  def self.down
    change_column :transfers, :transfers, :string
  end
end
