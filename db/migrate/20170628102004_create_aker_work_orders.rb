# Rails migration
class CreateAkerWorkOrders < ActiveRecord::Migration[4.2]
  def change
    create_table :aker_work_orders do |t|
      t.integer :aker_id
      t.timestamps null: false
    end
  end
end
