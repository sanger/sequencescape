class PrepareAssetsForSampleToAliquots < ActiveRecord::Migration
  def self.up
    add_column :assets, :has_been_visited, :boolean, :default => false
  end

  def self.down
    # Really no point in removing the column because it's a unidirectional migration
  end
end
