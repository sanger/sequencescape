class UndoAssetsPreparation < ActiveRecord::Migration
  def self.up
    remove_column :assets, :has_been_visited
  end

  def self.down
    # No need to add the column as this is a unidirectional migration
  end
end
