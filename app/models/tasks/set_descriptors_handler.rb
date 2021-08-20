module Tasks::SetDescriptorsHandler # rubocop:todo Style/Documentation
  def render_set_descriptors_task(_task, params)
    @batch = Batch.includes(:requests, :pipeline, :lab_events).find(params[:batch_id])
    @rits = @batch.pipeline.request_information_types
    @requests = @batch.ordered_requests
    @workflow = Workflow.includes(:tasks).find(params[:workflow_id])
    @task = @workflow.tasks[params[:id].to_i]
  end
end
