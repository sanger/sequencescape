module Tasks::SetCharacterisationDescriptorsHandler
  def do_set_characterisation_descriptors_task(task, params)
    unless @batch.started? || @batch.failed?
      @batch.start!(current_user)
    end



    @count = 0
    if params[:values].nil?
      @values = {}
    else
      @values = params[:values]
    end

    # Perform the necessary updates if we've passed batch creation
    updated = 0

    @batch.requests.each do |request|

      event = LabEvent.new(:batch_id => @batch.id, :description => @task.name)

      if params[:requests].present? && params[:requests]["#{request.id}"].present? && params[:requests]["#{request.id}"][:descriptors].present?
        # Descriptors: create description for event

        event.descriptors = params[:requests]["#{request.id}"][:descriptors]
        event.descriptor_fields = ordered_fields(params[:requests]["#{request.id}"][:fields])

      end

      event.save!
      current_user.lab_events << event
      request.lab_events << event


      unless request.asset.try(:resource)
        EventSender.send_request_update(request.id, "update", "Passed: #{@task.name}")
      end

      if request.has_passed(@batch, @task) || request.failed?
        updated += 1
      end
    end


    # Did all the requests get updated?
    if updated == @batch.requests.count
      eventify_batch @batch, @task
      return true
    else
      # Some requests have yet to pass this task
      # Construct a URL that contains a nested hash of values to display as defaults for the next request
      @params = { :batch_id => @batch.id, :workflow_id => @workflow.id, :values => @values }
      redirect_to url_for(flatten_hash(@params))
    end

    false
  end

  def render_set_characterisation_descriptors_task(task, params)
    @batch = Batch.find(params[:batch_id], :include => [:requests, :pipeline, :lab_events])
    @rits = @batch.pipeline.request_information_types
    @requests = @batch.ordered_requests

    unless @batch.started? || @batch.failed?
      @batch.start!(current_user)
    end

    @workflow = LabInterface::Workflow.find(params[:workflow_id], :include => [:tasks])
    @task = @workflow.tasks[params[:id].to_i]
    @stage = params[:id].to_i
    @count = 0
    if params[:values].nil?
      @values = {}
    else
      @values = params[:values]
    end


  end

end

