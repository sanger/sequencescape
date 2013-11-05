class AddMapLayoutColumn < ActiveRecord::Migration
  def self.up
    default = Map::AssetShape.find_by_name('Standard').id
    ActiveRecord::Base.transaction do
      add_column :maps, :asset_shape_id, :integer, :default => default, :null=>false
    end
  end

  def self.down
    ActiveRecord::Base.transaction do
      remove_column :maps, :asset_shape_id
    end
  end
end
