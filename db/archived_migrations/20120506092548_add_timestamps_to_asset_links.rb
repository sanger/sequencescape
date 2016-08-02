#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2012 Genome Research Ltd.
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
