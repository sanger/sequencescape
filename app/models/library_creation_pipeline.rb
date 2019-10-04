class LibraryCreationPipeline < Pipeline
  self.library_creation = true
  self.can_create_stock_assets = true
  self.generate_target_assets_on_batch_create = true
  self.asset_type = 'LibraryTube'

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
        parent_asset_with_request = asset.parents.find { |parent| !parent.requests.empty? }
        request = parent_asset_with_request.requests.find_by(state: 'pending', request_type_id: request_type_id)
        request.create_batch_request!(batch: batch, position: asset.map.location_id)
        request.update!(target_asset: asset)
        request.start!
      end
    end
    batch
  end
end
