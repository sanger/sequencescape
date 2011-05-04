class AddIndexToSampleIdInAssets < ActiveRecord::Migration
  def self.up
    add_index :assets, :sample_id
  end

  def self.down
    remove_index :assets, :sample_id
  end
end