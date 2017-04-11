# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2015 Genome Research Ltd.

##
# Set on a multiplexed request_type
# Pools based on the row of the source asset.
# WARNING: If target assets are to be created upfront, source assets must be defined
# WARNING: Will pool based on source asset location, not target. So may show odd behaviour
# with re-arrays.
module RequestType::PoolingMethod::PlateRow
  def pool_count
    pooling_options[:pool_count]
  end

  def pool_index_for_asset(source_asset)
    # This isn't ideal. We can't get the pool index until we have a source asset.
    return 0 unless source_asset.present?
    source_asset.map.row
  end

  def pool_index_for_request(request)
    return pool_index_for_asset(request.asset) if request.asset.present?
    # If we don't have an asset yet, look upstream. This assumes no
    # re-arraying has taken place.
    raise StandardError, 'Finding the pool index before requests are attached is unsupported'
  end
end
