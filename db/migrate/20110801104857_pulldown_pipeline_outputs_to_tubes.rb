class PulldownPipelineOutputsToTubes < ActiveRecord::Migration
  def self.up
    RequestType.find_by_key('pulldown_multiplexing').update_attributes!(:target_asset_type => 'PulldownMultiplexedLibraryTube')
  end

  def self.down
    RequestType.find_by_key('pulldown_multiplexing').update_attributes!(:target_asset_type => nil)
  end
end
