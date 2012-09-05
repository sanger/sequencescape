module Tasks::SmrtCellsHandler
  def render_smrt_cells_task(task, params)
    @requests = task.find_batch_requests(params[:batch_id]).select{ |request| request.state != 'failed' }
  end

  def do_smrt_cells_task(task, params)
    requests = task.find_batch_requests(params[:batch_id])

    params[:request].each do |request_id, smrt_cells_available|
      if smrt_cells_available.blank? ||  ! smrt_cells_available.to_i.is_a?(Integer) || smrt_cells_available.to_i < 0
        flash[:error] = "Invalid SMRTcell value"
        return false
      end

      requests_found = requests.select{ |request| request.id == request_id.to_i }
      request = requests_found.first
      if request.nil?
        flash[:error] = "Couldnt find Request #{request_id}"
        return false
      end

      request.target_asset.pac_bio_library_tube_metadata.update_attributes!(:smrt_cells_available => smrt_cells_available.to_i)
    end

    true
  end
end
