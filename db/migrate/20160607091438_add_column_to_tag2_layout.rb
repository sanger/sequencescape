# Rails migration
# Allow tag2 templates to be applied to partial plates by specifying wells
class AddColumnToTag2Layout < ActiveRecord::Migration
  def change
    add_column :tag2_layouts, :target_well_locations, :text
  end
end
