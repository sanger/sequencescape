class AddDefaultStateToPlatePurpose < ActiveRecord::Migration
  def self.up
    add_column :plate_purposes, :default_state, :string, :default => 'pending'
  end

  def self.down
    remove_column :plate_purposes, :default_state
  end
end
