class AddPlatePurposeRelationshipToTasks < ActiveRecord::Migration
  def self.up
    add_column :tasks, :purpose_id, :integer
  end

  def self.down
    remove_column :tasks, :purpose_id
  end
end
