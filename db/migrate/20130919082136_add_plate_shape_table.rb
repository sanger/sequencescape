class AddPlateShapeTable < ActiveRecord::Migration
  def self.up
    create_table :asset_shapes do |t|
      t.string 'name', :null => false
      t.integer 'horizontal_ratio', :null => false
      t.integer 'vertical_ratio', :null => false
      t.string  'description_strategy', :null => false
      t.timestamps
    end
  end

  def self.down
    drop_table :asset_shapes
  end
end
