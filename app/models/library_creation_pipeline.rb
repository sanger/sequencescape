class LibraryCreationPipeline < Pipeline
  def library_creation?
    true
  end

  def pulldown?
    false
  end

  def update_detached_request(batch, request)
    super
    batch.remove_link(request)
  end

  # This is specific for multiplexing batches for plates
  def create_batch_from_assets(assets)
    batch = create_batch
    assets.each do |asset|
      parent_asset_with_request = asset.parents.select{|parent| ! parent.requests.empty? }.first
      request = parent_asset_with_request.requests.find_by_state_and_request_type_id("pending", self.request_type_id)
      request.create_batch_request!(:batch => batch, :position => asset.map.location_id)
      request.update_attributes!(:state => 'started', :target_asset => asset)
    end
    batch
  end
end
