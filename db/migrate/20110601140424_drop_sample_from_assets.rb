class DropSampleFromAssets < ActiveRecord::Migration
  def self.up
    rename_column :assets, :sample_id, :legacy_sample_id
  end

  def self.down
    rename_column :assets, :legacy_sample_id, :sample_id
  end
end
