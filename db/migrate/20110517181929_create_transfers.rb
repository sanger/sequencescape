class CreateTransfers < ActiveRecord::Migration
  def self.up
    create_table :transfers do |t|
      t.timestamps
      t.string :sti_type
      t.references :source
      t.references :destination, :polymorphic => true
      t.string :transfers, :limit => 1024
    end
  end

  def self.down
    drop_table :transfers
  end
end
