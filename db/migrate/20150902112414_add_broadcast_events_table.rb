class AddBroadcastEventsTable < ActiveRecord::Migration
  def self.up
    create_table :broadcast_events do |t|
      t.string :sti_type
      t.string :seed_type
      t.integer :seed_id
      t.timestamps
    end
  end

  def self.down
    drop_table :broadcast_events
  end
end
