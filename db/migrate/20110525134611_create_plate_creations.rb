#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2011 Genome Research Ltd.
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
