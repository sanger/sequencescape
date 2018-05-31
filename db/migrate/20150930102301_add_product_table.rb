
class AddProductTable < ActiveRecord::Migration
  def self.up
    create_table :products do |t|
      t.string :name, null: false
      t.timestamps
      t.datetime :deprecated_at
    end
  end

  def self.down
    drop_table :products
  end
end
