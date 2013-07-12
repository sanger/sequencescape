module Tasks::StartBatchHandler

  def do_start_batch_task(task, params)
    Batch.find(params[:batch_id]).start!(current_user) unless @batch.started? or @batch.failed?
    next_stage = params['id'].to_i+1
    redirect_to(:controller => "workflows", :action => "stage", :id => next_stage, :batch_id => params[:batch_id], :workflow_id => params[:workflow_id])
  end
end
