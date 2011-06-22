class AddCanBeConsideredAStockPlateToPlatePurposes < ActiveRecord::Migration
  def self.up
    add_column :plate_purposes, :can_be_considered_a_stock_plate, :boolean, :default => false, :null => false
  end

  def self.down
    remove_column :plate_purposes, :can_be_considered_a_stock_plate
  end
end
