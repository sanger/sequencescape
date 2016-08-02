#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2011 Genome Research Ltd.
class CreateStateChanges < ActiveRecord::Migration
  def self.up
    create_table :state_changes do |t|
      t.references :user
      t.references :target
      t.string     :contents, :limit => 1024
      t.string     :previous_state
      t.string     :target_state

      t.timestamps
    end
  end

  def self.down
    drop_table :state_changes
  end
end
