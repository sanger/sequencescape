# Rails migration
class AddStateToWorkOrder < ActiveRecord::Migration[5.1]
  def change
    add_column :work_orders, :state, :string
  end
end
