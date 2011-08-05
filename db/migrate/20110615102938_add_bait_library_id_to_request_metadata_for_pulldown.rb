class AddBaitLibraryIdToRequestMetadataForPulldown < ActiveRecord::Migration
  def self.up
    add_column(:request_metadata, :bait_library_id, :integer)
  end

  def self.down
    remove_column(:request_metadata, :bait_library_id)
  end
end
