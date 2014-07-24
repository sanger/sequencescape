class AddMinSizeToPipelines < ActiveRecord::Migration
  def self.up
    add_column :pipelines, :min_size, :integer, :null => true
  end

  def self.down
    remove_column :pipelines, :min_size
  end
end
