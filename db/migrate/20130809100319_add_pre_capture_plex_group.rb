class AddPreCapturePlexGroup < ActiveRecord::Migration
  def self.up
    create_table :pre_capture_pools do |t|
      t.column :created_at, :datetime
      t.column :updated_at, :datetime
    end
  end

  def self.down
    drop_table :pre_capture_pools
  end
end
