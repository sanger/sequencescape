#This file is part of SEQUENCESCAPE; it is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2015 Genome Research Ltd.

class AddProductTable < ActiveRecord::Migration
  def self.up
    create_table :products do |t|
      t.string :name, :null => false
      t.timestamps
      t.datetime :deprecated_at
    end
  end

  def self.down
    drop_table :products
  end
end
