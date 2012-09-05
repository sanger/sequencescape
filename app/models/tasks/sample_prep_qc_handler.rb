module Tasks::SamplePrepQcHandler
  def render_sample_prep_qc_task(task, params)
    @requests = task.find_batch_requests(params[:batch_id])
  end

  def do_sample_prep_qc_task(task, params)
    requests = task.find_batch_requests(params[:batch_id])

    params[:request].each do |request_id, qc_status|
      requests_found = requests.select{ |request| request.id == request_id.to_i }
      request = requests_found.first
      if request.nil?
        flash[:error] = "Couldnt find Request #{request_id}"
        return false
      end
      if qc_status == "failed"
        request.fail!
      elsif qc_status == "passed"
        request.pass!
      else
        flash[:error] = "Invalid QC state for #{request_id}"
        return false
      end
    end

    true
  end

end
