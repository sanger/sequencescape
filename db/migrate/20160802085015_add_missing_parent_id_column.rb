class AddMissingParentIdColumn < ActiveRecord::Migration
  def change
    change_table :plate_conversions do |t|
      t.integer :parent_id
    end
  end
end
