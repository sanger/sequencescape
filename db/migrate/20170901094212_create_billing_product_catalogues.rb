class CreateBillingProductCatalogues < ActiveRecord::Migration
  def change
    create_table :billing_product_catalogues do |t|
      t.string :name

      t.timestamps null: false
    end
  end
end
