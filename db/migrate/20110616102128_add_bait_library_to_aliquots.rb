class AddBaitLibraryToAliquots < ActiveRecord::Migration
  def self.up
    add_column :aliquots, :bait_library_id, :integer
  end

  def self.down
    remove_column :aliquots, :bait_library_id
  end
end
