##
# Set on a multiplexed request_type
# Pools based on the row of the source asset.
# WARNING: If target assets are to be created upfront, source assets must be defined
# WARNING: Will pool based on source asset location, not target. So may show odd behaviour
# with re-arrays.
module RequestType::Pooling::PlateRow

  def self.pool_count
    8
  end

  def self.pool_index_for(source_asset)
    # This isn't ideal. We can't get the pool index until we have a source asset.
    return 0 unless source_asset.present?
    source_asset.map.row
  end
end
