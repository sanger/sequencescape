# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2007-2011,2012,2014,2015 Genome Research Ltd.

class LibraryCreationPipeline < Pipeline
  self.library_creation = true
  self.can_create_stock_assets = true

  def update_detached_request(batch, request)
    super
    batch.remove_link(request)
  end

  # This is specific for multiplexing batches for plates
  # Is this still used?
  def create_batch_from_assets(assets)
    batch = create_batch
    ActiveRecord::Base.transaction do
      assets.each do |asset|
        parent_asset_with_request = asset.parents.select { |parent| !parent.requests.empty? }.first
        request = parent_asset_with_request.requests.find_by(state: 'pending', request_type_id: request_type_id)
        request.create_batch_request!(batch: batch, position: asset.map.location_id)
        request.update_attributes!(target_asset: asset)
        request.start!
      end
    end
    batch
  end
end
