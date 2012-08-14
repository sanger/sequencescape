class ConstrainAssetsToSingleLocation < ActiveRecord::Migration
  def self.up
    alter_table(:location_associations) do
      rename_column(:locatable_id, :locatable_id, :integer, :null => false)
      rename_column(:location_id,  :location_id,  :integer, :null => false)
      add_index(:locatable_id, :name => 'single_location_per_locatable_idx', :unique => true)
      remove_index(:name => 'index_location_associations_on_locatable_id')
    end
  end

  def self.down
    alter_table(:location_associations) do
      rename_column(:locatable_id, :locatable_id, :integer)
      rename_column(:location_id,  :location_id,  :integer)
      remove_index(:name => 'single_location_per_locatable_idx')
      add_index(:locatable_id, :name => 'index_location_associations_on_locatable_id')
    end
  end
end
