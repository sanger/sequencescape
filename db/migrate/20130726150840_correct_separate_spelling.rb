class CorrectSeparateSpelling < ActiveRecord::Migration
  def self.up
    rename_column :study_metadata, :seperate_y_chromosome_data, :separate_y_chromosome_data
  end

  def self.down
    rename_column :study_metadata, :separate_y_chromosome_data, :seperate_y_chromosome_data
  end
end
