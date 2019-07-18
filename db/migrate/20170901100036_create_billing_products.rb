# Rails migration
class CreateBillingProducts < ActiveRecord::Migration[4.2]
  def change
    create_table :billing_products do |t|
      t.string :name
      t.string :identifier
      t.integer :category
      t.references :billing_product_catalogue, null: false, foreign_key: true

      t.timestamps null: false
    end
  end
end
