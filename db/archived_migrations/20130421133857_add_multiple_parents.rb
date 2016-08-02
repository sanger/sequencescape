#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2013 Genome Research Ltd.
class AddMultipleParents < ActiveRecord::Migration
  def self.up
    ActiveRecord::Base.transaction do
      create_table :asset_creation_parents do |t|
        t.references :asset_creation
        t.references :parent
        t.timestamps
      end
    end
  end

  def self.down
    ActiveRecord::Base.transaction do
      drop_table :asset_creation_parents
    end
  end
end
