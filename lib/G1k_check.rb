#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2007-2011,2012 Genome Research Ltd.
Request.find_all_by_request_type_id([2,3]).each do |req|
  if req.asset && req.asset.parent
    req.asset.parent.requests.each do |lc|
      if req.item_id != lc.item_id && !lc.target_asset.nil? && lc.target_asset == req.asset
        puts "#{req.id} #{req.item_id} #{req.asset_id} #{req.state} #{req.study.name} #{lc.id} #{lc.item_id} #{lc.target_asset_id} #{lc.state} #{lc.study.name}"
              puts " req.item_id = #{lc.item_id}"
      end
    end
  end
end
