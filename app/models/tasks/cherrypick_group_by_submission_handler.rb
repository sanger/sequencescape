module Tasks::CherrypickGroupBySubmissionHandler
  def do_cherrypick_group_by_submission_task(task,params)
    if ! task.valid_params?(params)
      flash[:warning] = "Invalid values typed in"
      redirect_to :action => 'stage', :batch_id => @batch.id, :workflow_id => @workflow.id, :id => (0).to_s
      return false
    end

    volume_required= params[:volume_required]
    concentration_required = params[:concentration_required]
    plate_purpose = PlatePurpose.find(params[:plate_purpose_id])

    batch = Batch.find(params[:batch_id], :include => [:requests, :pipeline, :lab_events])
    requests = batch.ordered_requests

    ActiveRecord::Base.transaction do
      task.send(
        :"pick_by_#{params[:cherrypick][:action]}",
        batch, requests, plate_purpose, params
      )
    end

    true
#  rescue => exception
#    debugger
#    flash[:error] = exception.message
#    return false
  end

  def render_cherrypick_group_by_submission_task(task,params)
    @plate_purpose_options = task.plate_purpose_options(@batch)
  end
end
