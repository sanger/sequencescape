class AddTagIdIndexToAliquots < ActiveRecord::Migration
  def self.up
    add_index(:aliquots, :tag_id, :name => 'tag_id_idx')
  end

  def self.down
    remove_index(:aliquots, :name => 'tag_id_idx')
  end
end
