#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2011 Genome Research Ltd.
class AddSwipecardCodeUser < ActiveRecord::Migration
  def self.up
    add_column :users, :encrypted_swipecard_code, :string, :limit => 40

    add_index :users, :encrypted_swipecard_code
  end

  def self.down
    remove_column :users, :encrypted_swipecard_code
  end
end
