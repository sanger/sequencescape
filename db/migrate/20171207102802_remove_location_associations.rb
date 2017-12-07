class RemoveLocationAssociations < ActiveRecord::Migration[5.1]
  def change
    drop_table :location_associations
  end
end
