class CreateAkerProducts < ActiveRecord::Migration[5.1]
  def change
    create_table :aker_products do |t|
      t.string :name
      t.string :description
      t.references :aker_catalogue, index: true
      t.integer :product_version, default: 1
      t.boolean :availability, default: true
      t.string :requested_biomaterial_type
      t.string :product_class
      t.timestamps null: false
    end
  end
end
