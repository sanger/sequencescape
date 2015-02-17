#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2011 Genome Research Ltd.
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
