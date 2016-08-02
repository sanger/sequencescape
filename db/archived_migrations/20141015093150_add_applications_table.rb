#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2014 Genome Research Ltd.
class AddApplicationsTable < ActiveRecord::Migration
  def self.up

    create_table :api_applications do |t|
      t.string :name, :null => false
      t.string :key,  :null => false
      t.string :contact, :null => false
      t.text   :description
      t.string :privilege, :null => false
    end

    add_index :api_applications, :key
  end

  def self.down
    drop_table :api_applications
  end
end
