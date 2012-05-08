class AddTimestampsToAssetLinks < ActiveRecord::Migration
  def self.up
    alter_table(:asset_links) do |t|
      t.add_column(:created_at, :timestamp, :null => false)
      t.add_column(:updated_at, :timestamp, :null => false)
    end
    AssetLink.connection.execute("UPDATE asset_links SET created_at=now(), updated_at=now()")
  end

  def self.down
    alter_table(:asset_links) do |t|
      t.remove_column(:created_at)
      t.remove_column(:updated_at)
    end
  end
end
