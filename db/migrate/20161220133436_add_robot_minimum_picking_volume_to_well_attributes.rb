# Rails migration
class AddRobotMinimumPickingVolumeToWellAttributes < ActiveRecord::Migration
  def change
    add_column :well_attributes, :robot_minimum_picking_volume, :float
  end
end
