class AddLabActivityFlag < ActiveRecord::Migration
  def self.up
    ActiveRecord::Base.transaction do
      add_column :tasks, :lab_activity, :boolean
    end
  end

  def self.down
    ActiveRecord::Base.transaction do
      remove_column :tasks, :lab_activity
    end
  end
end
