class AddDefaultToDataReleaseStudyType < ActiveRecord::Migration
  def self.up
    add_column :data_release_study_types, :is_default, :boolean, :default => false
  end

  def self.down
    remove_column :data_release_study_types, :is_default
  end
end
