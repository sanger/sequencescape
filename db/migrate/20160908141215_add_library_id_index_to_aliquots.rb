# Rails migration
class AddLibraryIdIndexToAliquots < ActiveRecord::Migration
  def change
    add_index :aliquots, :library_id
  end
end
