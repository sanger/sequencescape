class RenameCanBeConsideredAStockPlate < ActiveRecord::Migration
  def change
    rename_column :plate_purposes, 'can_be_considered_a_stock_plate', 'stock_plate'
  end
end
