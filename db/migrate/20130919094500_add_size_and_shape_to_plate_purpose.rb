class AddSizeAndShapeToPlatePurpose < ActiveRecord::Migration
  def self.up
    default = Map::AssetShape.find_by_name('Standard').id
    ActiveRecord::Base.transaction do
      add_column :plate_purposes, :size, :integer, :default=>96, :null=>true
      add_column :plate_purposes, :asset_shape_id, :integer, :default=>default, :null=>false
      Purpose.find_by_name('Sequenom').update_attributes!(:size=>384)
    end
  end

  def self.down
    ActiveRecord::Base.transaction do
      remove_column :plate_purposes, :size
      remove_column :plate_purposes, :asset_shape_id
    end
  end
end
