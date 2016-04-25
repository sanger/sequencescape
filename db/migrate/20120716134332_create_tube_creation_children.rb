#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2012 Genome Research Ltd.
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
