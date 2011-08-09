class AddIndexToAliquotsSampleId < ActiveRecord::Migration
  def self.up
    add_index :aliquots, :sample_id
  end

  def self.down
    remove_index :aliquots, :sample_id
  end
end
