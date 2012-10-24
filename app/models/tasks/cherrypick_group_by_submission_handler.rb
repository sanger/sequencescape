module Tasks::CherrypickGroupBySubmissionHandler
  def do_cherrypick_group_by_submission_task(task,params)
    if ! task.valid_params?(params)
      flash[:warning] = "Invalid values typed in"
      redirect_to :action => 'stage', :batch_id => @batch.id, :workflow_id => @workflow.id, :id => (0).to_s
      return false
    end

    # If there was a plate scanned then we take its purpose, otherwise we use the purpose specified
    # in the dropdown.
    partial_plate, plate_purpose = nil, PlatePurpose.find(params[:plate_purpose_id])
    if not params[:existing_plate].blank?
      partial_plate, plate_purpose = Plate.with_machine_barcode(params[:existing_plate]).first, nil
      if partial_plate.nil?
        flash[:error] = "Cannot find the partial plate #{params[:existing_plate].inspect}"
        redirect_to :action => 'stage', :batch_id => @batch.id, :workflow_id => @workflow.id, :id => (0).to_s
        return false
      end
    end

    robot = Robot.find(params[:robot])
    batch = Batch.find(params[:batch_id], :include => [:requests, :pipeline, :lab_events])

    ActiveRecord::Base.transaction do
      task.send(
        :"pick_by_#{params[:cherrypick][:action]}",
        batch.ordered_requests, robot, partial_plate || plate_purpose, params
      )
    end

    true
  rescue => exception
    flash[:error] = exception.message
    false
  end

  def render_cherrypick_group_by_submission_task(task,params)
    @plate_purpose_options = task.plate_purpose_options(@batch)
  end
end
