#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2013 Genome Research Ltd.
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
