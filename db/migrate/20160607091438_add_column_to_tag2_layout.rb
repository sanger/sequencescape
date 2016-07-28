class AddColumnToTag2Layout < ActiveRecord::Migration
  def change
    add_column :tag2_layouts, :target_well_locations, :text
  end
end
