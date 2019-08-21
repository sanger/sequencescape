# Rails migration
class AddWorkOrdersTable < ActiveRecord::Migration[5.1]
  def change
    create_table :work_orders do |t|
      t.references :work_order_type, null: false, foreign_key: true
      t.timestamps null: false
    end
  end
end
