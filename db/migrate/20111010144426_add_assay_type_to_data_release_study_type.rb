class AddAssayTypeToDataReleaseStudyType < ActiveRecord::Migration
  def self.up
    add_column :data_release_study_types, :is_assay_type, :boolean, :default => false
  end

  def self.down
    remove_column :data_release_study_types, :is_assay_type
  end
end
