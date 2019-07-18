# Rails migration
class CreatePlateTypes < ActiveRecord::Migration
  def change
    create_table :plate_types do |t|
      t.string :name
      t.integer :maximum_volume

      t.timestamps null: false
    end
  end
end
