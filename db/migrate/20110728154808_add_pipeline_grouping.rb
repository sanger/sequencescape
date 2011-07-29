class AddPipelineGrouping < ActiveRecord::Migration
  def self.up
    add_column :pipelines, :group_name, :string
  end

  def self.down
    remove_column :pipelines, :group_name
  end
end
