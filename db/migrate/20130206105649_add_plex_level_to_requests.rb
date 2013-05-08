class AddPlexLevelToRequests < ActiveRecord::Migration
  def self.up
    ActiveRecord::Base.transaction do
      add_column :request_metadata, :pre_capture_plex_level, :integer
    end
  end

  def self.down
    ActiveRecord::Base.transaction do
      add_column :request_metadata, :pre_capture_plex_level
    end
  end
end
