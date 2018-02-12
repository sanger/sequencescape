class CreateJoinTableAkerProductsProcesses < ActiveRecord::Migration[5.1]
  def change
    create_table :aker_products_processes do |t|
      t.references :aker_product, index: true
      t.references :aker_process, index: true
      t.integer :stage
      t.timestamps null: false
    end
  end
end
