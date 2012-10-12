class AddDefaultLocationToPurposes < ActiveRecord::Migration
  def self.up
    add_column(:plate_purposes, :default_location_id, :integer)
  end

  def self.down
    remove_column(:plate_purposes, :default_location_id)
  end
end
