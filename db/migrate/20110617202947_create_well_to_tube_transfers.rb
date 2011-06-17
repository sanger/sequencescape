class CreateWellToTubeTransfers < ActiveRecord::Migration
  def self.up
    create_table :well_to_tube_transfers do |t|
      t.references :transfer, :null => false
      t.references :destination, :null => false
      t.string :source
    end
  end

  def self.down
    drop_table :well_to_tube_transfers
  end
end
