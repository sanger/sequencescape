# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2015 Genome Research Ltd.

class AddPlateCreatorParentPurposesTable < ActiveRecord::Migration
  def self.up
    create_table :plate_creator_parent_purposes do |t|
      t.references :plate_creator, :null => false
      t.references :plate_purpose, :null => false
      t.timestamps
    end
  end

  def self.down
    drop_table :plate_creator_parent_purposes
  end
end
