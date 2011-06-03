class DropSampleFromAssets < ActiveRecord::Migration
  def self.up
    remove_column :assets, :sample_id
  end

  def self.down
    add_column :assets, :sample_id, :integer
  end
end
