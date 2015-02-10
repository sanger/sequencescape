#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2011 Genome Research Ltd.
class PulldownPipelineOutputsToTubes < ActiveRecord::Migration
  def self.up
    RequestType.find_by_key('pulldown_multiplexing').update_attributes!(:target_asset_type => 'PulldownMultiplexedLibraryTube')
  end

  def self.down
    RequestType.find_by_key('pulldown_multiplexing').update_attributes!(:target_asset_type => nil)
  end
end
