#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2015 Genome Research Ltd.
class AddBroadcastEventsTable < ActiveRecord::Migration
  def self.up
    create_table :broadcast_events do |t|
      t.string :sti_type
      t.string :seed_type
      t.integer :seed_id
      t.integer :user_id
      t.text :properties
      t.timestamps
    end
  end

  def self.down
    drop_table :broadcast_events
  end
end
