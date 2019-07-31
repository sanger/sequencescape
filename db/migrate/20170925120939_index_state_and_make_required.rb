# Rails migration
class IndexStateAndMakeRequired < ActiveRecord::Migration[5.1]
  def change
    change_column_null(:work_orders, :state, false)
    add_index(:work_orders, %i[work_order_type_id state])
  end
end
