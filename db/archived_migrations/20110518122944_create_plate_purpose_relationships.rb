#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2011 Genome Research Ltd.
class CreatePlatePurposeRelationships < ActiveRecord::Migration
  def self.up
    create_table :plate_purpose_relationships do |t|
      t.references :parent
      t.references :child
    end
  end

  def self.down
    drop_table :plate_purpose_relationships
  end
end
