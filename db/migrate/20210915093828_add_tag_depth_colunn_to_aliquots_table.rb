class AddTagDepthColunnToAliquotsTable < ActiveRecord::Migration[6.0]
  def up
    add_column :aliquots, :tag_depth, :integer, null: false, default: 1
    remove_index :aliquots, name: :aliquot_tags_and_tag2s_are_unique_within_receptacle
    # This index has been added to support pipelines, such as Cardinal,
    # where many untagged samples can be added to a pool, which is assigned a well,
    # which shouldn't trigger tag clash error
    add_index(:aliquots, [:receptacle_id, :tag_id, :tag2_id, :tag_depth], unique: true, name: 'aliquot_tag_tag2_and_tag_depth_are_unique_within_receptacle')
  end

  def down
    remove_index :aliquots, name: :aliquot_tag_tag2_and_tag_depth_are_unique_within_receptacle
    add_index(:aliquots, [:receptacle_id, :tag_id, :tag2_id], unique: true, name: 'aliquot_tags_and_tag2s_are_unique_within_receptacle')
    remove_column :aliquots, :tag_depth
  end
end
