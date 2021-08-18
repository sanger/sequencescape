module Tasks::SetCharacterisationDescriptorsHandler # rubocop:todo Style/Documentation
  # rubocop:todo Metrics/PerceivedComplexity
  # rubocop:todo Metrics/MethodLength
  # rubocop:todo Metrics/AbcSize
  def do_set_characterisation_descriptors_task(_task, params) # rubocop:todo Metrics/CyclomaticComplexity
    @count = 0
    @values = params[:values].nil? ? {} : params[:values]

    # Perform the necessary updates if we've passed batch creation
    updated = 0

    @batch.requests.each do |request|
      event = LabEvent.new(batch_id: @batch.id, description: @task.name)

      if params[:requests].present? && params[:requests][(request.id).to_s].present? &&
           params[:requests][(request.id).to_s][:descriptors].present?
        # Descriptors: create description for event

        event.descriptors = params[:requests][(request.id).to_s][:descriptors]
      end

      event.save!
      current_user.lab_events << event
      request.lab_events << event

      EventSender.send_request_update(request, 'update', "Passed: #{@task.name}") unless request.asset.try(:resource)

      updated += 1 if request.has_passed(@batch, @task) || request.failed?
    end

    # Did all the requests get updated?
    if updated == @batch.requests.count
      eventify_batch @batch, @task
      return true
    else
      # Some requests have yet to pass this task
      # Construct a URL that contains a nested hash of values to display as defaults for the next request
      @params = { batch_id: @batch.id, workflow_id: @workflow.id, values: @values }
      redirect_to url_for(flatten_hash(@params))
    end

    false
  end

  # rubocop:enable Metrics/AbcSize
  # rubocop:enable Metrics/MethodLength
  # rubocop:enable Metrics/PerceivedComplexity

  def render_set_characterisation_descriptors_task(_task, params) # rubocop:todo Metrics/AbcSize
    @batch = Batch.includes(:requests, :pipeline, :lab_events).find(params[:batch_id])
    @rits = @batch.pipeline.request_information_types
    @requests = @batch.ordered_requests

    @workflow = Workflow.includes(:tasks).find(params[:workflow_id])
    @task = @workflow.tasks[params[:id].to_i]
    @stage = params[:id].to_i
    @values = params[:values].nil? ? {} : params[:values]
  end
end
