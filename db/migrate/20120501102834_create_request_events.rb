class CreateRequestEvents < ActiveRecord::Migration
  def self.up
    create_table :request_events do |t|
      t.integer :request_id, :null => false
      t.string  :event_name, :null => false
      t.string  :from_state # from_state can be null for request creation events
      t.string  :to_state,   :null => false
      t.integer :study_id
      t.integer :project_id
      t.integer :user_id

      t.timestamps
    end

  end

  def self.down
    drop_table :request_events
  end
end
