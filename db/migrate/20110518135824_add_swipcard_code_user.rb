class AddSwipcardCodeUser < ActiveRecord::Migration
  def self.up
    add_column :users, :encrypted_swipcard_code, :string, :limit => 40

    add_index :users, :encrypted_swipcard_code
  end

  def self.down
    remove_column :users, :encrypted_swipcard_code
  end
end
