class AddTimestampsToRolesUsers < ActiveRecord::Migration
  def self.up
    alter_table(:roles_users) do |t|
      t.add_column(:created_at, :timestamp, :null => false)
      t.add_column(:updated_at, :timestamp, :null => false)
    end
  end

  def self.down
    alter_table(:roles_users) do |t|
      t.remove_column(:created_at)
      t.remove_column(:updated_at)
    end
  end
end
