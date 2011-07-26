class CreateBaitLibraryLayouts < ActiveRecord::Migration
  def self.up
    create_table :bait_library_layouts do |t|
      t.references :user
      t.references :plate,  :null => false
      t.string     :layout, :limit => 1024

      t.timestamps
    end

    add_index :bait_library_layouts, :plate_id, :unique => true, :name => 'bait_libraries_are_laid_out_on_a_plate_once'
  end

  def self.down
    drop_table :bait_library_layouts
  end
end
