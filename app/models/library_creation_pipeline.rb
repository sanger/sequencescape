class LibraryCreationPipeline < Pipeline
  self.library_creation = true
  self.can_create_stock_assets = true
  self.generate_target_assets_on_batch_create = true
  self.asset_type = 'LibraryTube'

  def update_detached_request(batch, request)
    super
    batch.remove_link(request)
  end
end
