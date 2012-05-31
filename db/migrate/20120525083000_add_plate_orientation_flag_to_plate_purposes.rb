class AddPlateOrientationFlagToPlatePurposes < ActiveRecord::Migration
  def self.up
    ActiveRecord::Base.transaction do
      add_column :plate_purposes, :cherrypick_direction, :string, :null => false, :default => 'column'
    end
  end

  def self.down
    ActiveRecord::Base.transaction do
      remove_column :plate_purposes, :cherrypick_direction
    end
  end
end
