class AddNotValidForCreationFlagToStudyTypes < ActiveRecord::Migration
  def self.up
    add_column :study_types, :valid_for_creation, :boolean, :default => true, :null => false
  end

  def self.down
    remove_column :study_types, :valid_for_creation
  end
end
