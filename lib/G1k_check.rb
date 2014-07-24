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
