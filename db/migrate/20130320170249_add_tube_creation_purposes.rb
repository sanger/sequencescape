class AddTubeCreationPurposes < ActiveRecord::Migration
  def self.up
    create_table :specific_tube_creation_purposes do |t|
      t.references :specific_tube_creation
      t.references :tube_purpose
      t.timestamps
    end
  end

  def self.down
    drop_table :specific_tube_creation_purposes
  end
end
