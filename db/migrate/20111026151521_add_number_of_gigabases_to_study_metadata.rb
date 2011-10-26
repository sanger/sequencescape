class AddNumberOfGigabasesToStudyMetadata < ActiveRecord::Migration
  def self.up
    add_column :study_metadata, :number_of_gigabases_per_sample, :float
  end

  def self.down
    remove_column :study_metadata, :number_of_gigabases_per_sample
  end
end
