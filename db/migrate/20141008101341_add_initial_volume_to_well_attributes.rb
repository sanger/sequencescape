class AddInitialVolumeToWellAttributes < ActiveRecord::Migration
  def self.up
    add_column :well_attributes, :initial_volume, :float
  end

  def self.down
    add_column :well_attributes, :initial_volume
  end
end
