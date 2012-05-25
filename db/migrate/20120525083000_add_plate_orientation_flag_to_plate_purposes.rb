class AddPlateOrientationFlagToPlatePurposes < ActiveRecord::Migration
  def self.up
    ActiveRecord::Base.transaction do
      add_column :plate_purposes, :row_orientated, :boolean, :null => false, :default => false
    end
  end

  def self.down
    ActiveRecord::Base.transaction do
      remove_column :plate_purposes, :row_orientated
    end
  end
end
