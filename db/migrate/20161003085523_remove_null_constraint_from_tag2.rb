# Rails migration
class RemoveNullConstraintFromTag2 < ActiveRecord::Migration
  def up
    change_column :aliquots, :tag2_id, :integer, default: -1, null: true
  end

  def down
    change_column :aliquots, :tag2_id, :integer, default: -1, null: false
  end
end
