class AddPriorityToSubmission < ActiveRecord::Migration
  def self.up
    add_column :submissions, :priority, :integer, :limit => 1, :null => false, :default => 0
  end

  def self.down
    remove_column :submissions, :priority
  end
end
