class AddInitialTagToTagLayout < ActiveRecord::Migration
  def self.up
    ActiveRecord::Base.transaction do

      add_column :tag_layouts, :initial_tag, :integer, :null=>false, :default=>0
    end
  end

  def self.down
    ActiveRecord::Base.transaction do
      drop_column :tag_layouts, :initial_tag
    end
  end
end
