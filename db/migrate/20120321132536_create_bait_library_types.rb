class CreateBaitLibraryTypes < ActiveRecord::Migration
  def self.up
    ActiveRecord::Base.transaction do
      create_table :bait_library_types do |t|
        t.string :name, :null => false
        t.timestamps
      end
      add_index :bait_library_types, :name, :unique => true
      ['Standard','Custom - Pipeline', 'Custom - Customer'].each do |name|
        BaitLibraryType.create!(:name => name)
      end

      add_column :bait_libraries, :bait_library_type_id, :integer, :null => false
      BaitLibrary.all.each do |bait_library|
        bait_library.update_attributes(:bait_library_type => BaitLibraryType.find_by_name('Standard'))
      end
    end
  end

  def self.down
    ActiveRecord::Base.transaction do
      drop_table :bait_library_types
      remove_column :bait_libraries, :bait_library_type_id
    end
  end
end
