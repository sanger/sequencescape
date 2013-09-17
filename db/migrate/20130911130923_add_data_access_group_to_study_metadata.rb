class AddDataAccessGroupToStudyMetadata < ActiveRecord::Migration
  def self.up
    ActiveRecord::Base.transaction do
      add_column :study_metadata, :data_access_group, :string
    end
  end

  def self.down
    ActiveRecord::Base.transaction do
      remove_column :study_metadata, :data_access_group
    end
  end
end
