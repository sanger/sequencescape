class AddSeperateYChromosomeColumn < ActiveRecord::Migration
  def self.up
    ActiveRecord::Base.transaction do
      add_column :study_metadata, :seperate_y_chromosome_data, :boolean, :null => false, :default => false
    end
  end

  def self.down
    ActiveRecord::Base.transaction do
      remove_column :study_metadata, :seperate_y_chromosome_data
    end
  end
end
