class CreatePlateCreations < ActiveRecord::Migration
  def self.up
    create_table :plate_creations do |t|
      t.references :user
      t.references :parent
      t.references :child_plate_purpose
      t.references :child
      t.timestamps
    end
  end

  def self.down
    drop_table :plate_creations
  end
end
