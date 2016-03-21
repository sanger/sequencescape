#This file is part of SEQUENCESCAPE; it is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2015 Genome Research Ltd.

class AddAliquotIndexConstraintsToDatabase < ActiveRecord::Migration
  def self.up
    add_index :aliquot_indices, :aliquot_id, :unique => true
    add_index :aliquot_indices, [:lane_id,:aliquot_index], :unique => true
  end

  def self.down
    drop_index :aliquot_indices, :aliquot_id
    drop_index :aliquot_indices, [:lane_id,:aliquot_index]
  end
end
