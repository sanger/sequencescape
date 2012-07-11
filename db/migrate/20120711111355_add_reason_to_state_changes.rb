class AddReasonToStateChanges < ActiveRecord::Migration
  def self.up
    add_column(:state_changes, :reason, :string)
  end

  def self.down
    remove_column(:state_changes, :reason)
  end
end
