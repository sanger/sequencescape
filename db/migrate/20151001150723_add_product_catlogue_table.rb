
class AddProductCatlogueTable < ActiveRecord::Migration
  def self.up
    create_table :product_catalogues do |t|
      t.string :name, null: false
      t.string :selection_behaviour, null: false, default: 'SingleProduct'
      t.timestamps
    end
  end

  def self.down
    drop_table :product_catalogues
  end
end
