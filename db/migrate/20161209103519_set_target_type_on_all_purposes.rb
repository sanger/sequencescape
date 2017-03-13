class SetTargetTypeOnAllPurposes < ActiveRecord::Migration
  def up
    Purpose.where(target_type: nil).update_all(target_type: 'Plate')
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
