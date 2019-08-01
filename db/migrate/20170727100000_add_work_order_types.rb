# Rails migration
class AddWorkOrderTypes < ActiveRecord::Migration[5.1]
  def change
    create_table :work_order_types do |t|
      t.string :name, null: false, index: { unique: true }
      t.timestamps null: false
    end
  end
end
