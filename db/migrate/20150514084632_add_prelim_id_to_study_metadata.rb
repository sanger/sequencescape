class AddPrelimIdToStudyMetadata < ActiveRecord::Migration
  def self.up
    ActiveRecord::Base.transaction do
      add_column :study_metadata, :prelim_id, :string
      add_index :study_metadata, :prelim_id
    end
  end

  def self.down
    ActiveRecord::Base.transaction do
      remove_column :study_metadata, :prelim_id
      remove_index :study_metadata, :prelim_id
    end
  end
end
