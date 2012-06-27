class ConstrainStudySamples < ActiveRecord::Migration
  def self.up
    alter_table(:study_samples) do
      rename_column(:study_id, :study_id, :integer, :null => false)
      rename_column(:sample_id, :sample_id, :integer, :null => false)
      add_index([:sample_id, :study_id], :name => 'unique_samples_in_studies_idx', :unique => true)
    end
  end

  def self.down
    remove_index(:study_samples, :name => :unique_samples_in_studies_idx)
  end
end
