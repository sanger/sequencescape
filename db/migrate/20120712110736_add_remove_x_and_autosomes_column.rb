class AddRemoveXAndAutosomesColumn < ActiveRecord::Migration
  def self.up
    ActiveRecord::Base.transaction do
      add_column :study_metadata, :remove_x_and_autosomes, :string, :null => false, :default => 'No'
    end
  end

  def self.down
    ActiveRecord::Base.transaction do
      remove_column :study_metadata, :remove_x_and_autosomes
    end
  end
end
