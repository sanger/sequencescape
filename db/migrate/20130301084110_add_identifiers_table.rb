#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2013 Genome Research Ltd.
class AddIdentifiersTable < ActiveRecord::Migration
  def self.up
    create_table :order_roles do |t|
      t.string :role
      t.timestamps
    end
  end

  def self.down
    drop_table :order_roles
  end
end
