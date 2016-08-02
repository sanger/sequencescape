#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2013 Genome Research Ltd.
class AddRequestEventsTable < ActiveRecord::Migration
  def self.up
    ActiveRecord::Base.transaction do
      create_table :request_events do |t|
        t.references :request, :null => false
        t.string 'event_name', :null => false
        t.string 'from_state'
        t.string 'to_state'
        t.datetime 'current_from', :null => false
        t.datetime 'current_to'
      end

      add_index :request_events, [ :request_id, :current_to ]
      add_index :request_events, [ :request_id, :current_from, :current_to ], :unique => true
    end
  end

  def self.down
    ActiveRecord::Base.transaction do
      drop_table(:request_events)
    end
  end
end
