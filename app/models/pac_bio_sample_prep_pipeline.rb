class PacBioSamplePrepPipeline < Pipeline
  ALWAYS_SHOW_RELEASE_ACTIONS = true
  include Pipeline::GroupByParent

  self.requires_position = false
  self.inbox_eager_loading = :loaded_for_pacbio_inbox_display
  self.generate_target_assets_on_batch_create = true
  self.asset_type = 'PacBioLibraryTube'
  self.pick_to = false

  def allow_tag_collision_on_tagging_task?
    false
  end

  def post_release_batch(batch, _user)
    cancel_sequencing_requests_on_library_failure(batch)
    cancel_excess_sequencing_requests(batch)
  end

  def cancel_downstream_requests(request)
    request.next_requests.select(&:pending?).each(&:cancel_from_upstream!)
  end

  def cancel_sequencing_requests_on_library_failure(batch)
    batch.requests.each do |request|
      cancel_downstream_requests(request) if request.failed?
    end
  end

  def cancel_excess_sequencing_requests(batch)
    batch.requests.each do |request|
      smrt_cells_available = request.target_asset.labware.pac_bio_library_tube_metadata.smrt_cells_available
      smrt_cells_requested = number_of_smrt_cells_requested(request)
      next if smrt_cells_available.nil? || smrt_cells_requested.nil?

      if smrt_cells_available < smrt_cells_requested
        cancel_excess_downstream_requests(request, (smrt_cells_requested - smrt_cells_available))
      end
    end
  end

  def cancel_excess_downstream_requests(request, number_to_cancel)
    request.next_requests.select(&:pending?).each_with_index do |sequencing_request, index|
      sequencing_request.cancel_from_upstream! if index < number_to_cancel
    end
  end

  def number_of_smrt_cells_requested(request)
    request.next_requests.count(&:pending?)
  end
end
