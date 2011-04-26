class RemoveUnusedHolderColumns < ActiveRecord::Migration
  def self.up
    alter_table(:assets) do 
      remove_column(:holder_type)
      remove_column(:holder_id)
    end
  end

  def self.down
    alter_table(:assets) do
      add_column(:holder_type, :string, :default => 'Location', :limit => 50)
      add_column(:holder_id, :integer)
    end
  end
end
