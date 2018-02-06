class CreateJoinTableAkerProductProcesses < ActiveRecord::Migration[5.1]
  def change
    create_table :aker_product_processes do |t|
      t.references :aker_product
      t.references :aker_process
      t.integer :stage
      t.timestamps null: false
    end
  end
end
