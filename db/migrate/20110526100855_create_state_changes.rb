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
