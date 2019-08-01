# Plate conversions allowed specification of parent, but didn't track it.
class AddMissingParentIdColumn < ActiveRecord::Migration
  def change
    change_table :plate_conversions do |t|
      t.integer :parent_id
    end
  end
end
