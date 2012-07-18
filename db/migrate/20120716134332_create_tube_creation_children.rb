class CreateTubeCreationChildren < ActiveRecord::Migration
  def self.up
    create_table(:tube_creation_children) do |t|
      t.timestamps
      t.integer(:tube_creation_id, :null => false)
      t.integer(:tube_id, :null => false)
    end
  end

  def self.down
    drop_table(:tube_creation_children)
  end
end
