#This file is part of SEQUENCESCAPE; it is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2015 Genome Research Ltd.
class AddPoolingMethodsTable < ActiveRecord::Migration
  def self.up
    create_table :pooling_methods do |t|
      t.string   "pooling_behaviour",        :limit => 50, :null => false
      t.text     "pooling_options"
    end

  end

  def self.down
    drop_table :pooling_methods
  end
end
