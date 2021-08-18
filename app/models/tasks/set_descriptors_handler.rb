module Tasks::SetDescriptorsHandler # rubocop:todo Style/Documentation
  # rubocop:todo Metrics/PerceivedComplexity
  # rubocop:todo Metrics/MethodLength
  # rubocop:todo Metrics/AbcSize
  def do_set_descriptors_task(_task, params) # rubocop:todo Metrics/CyclomaticComplexity
    @batch = Batch.includes(:requests, :pipeline, :lab_events).find(params[:batch_id])

    # Determines files shown on the table at the top of the page
    @rits = @batch.pipeline.request_information_types
    @requests = @batch.ordered_requests

    @workflow = Workflow.includes(:tasks).find(params[:workflow_id])
    @task = @workflow.tasks[params[:id].to_i]
    @stage = params[:id].to_i
    @values = params[:values].nil? ? {} : params[:values]

    return false if params[:next_stage].nil?

    # Front end renders checkboxes in the form:
    # <input name="request[20251826]" id="sample 1 checkbox" class="sample_check select_all_target" value="on" type="checkbox" checked="">
    # We don't have hidden input fields of the same name, so params[:request] looks as follows:
    # { '123' => 'on', '124' => 'on' }
    # Unchecked requests are *not* listed in the hash.
    checked_requests = params.fetch(:request, {}).keys.map(&:to_i)

    # Process each request that has been checked.

    @batch.requests.each do |request|
      next unless checked_requests.include?(request.id)

      event = LabEvent.new(batch: @batch, description: @task.name, user: current_user, eventful: request)

      # This is called when a single set of fields is used (ie. Task#per_item == 0)
      # and called over and over based on the selected requests
      # The fields for a descriptor look like this:
      # <td width="65%">
      #   <input value="" type="text" name="descriptors[Operator]" id="descriptors_Operator">
      # </td>
      # This results in:
      # params[:descriptors] => <ActionController::Parameters {"Operator"=>"operator_value", "Workflow (Standard or Xp)"=>"Standard", "DPX1"=>"dpx1_value", "DPX2"=>"dpx2_value", "DPX3"=>"dpx3_value", "NovaSeq Xp Mainfold"=>"nov_seq_xp_val", "Pipette Carousel"=>"pippet_val", "PhiX lot %23"=>"phix_val", "PhiX %25"=>"Phix%_val", "Lane loading concentration (pM)"=>"lan_conc_val", "Comment"=>"comment_val"} permitted: true>
      if params[:descriptors].present?
        event.descriptors = params[:descriptors].to_unsafe_hash

        # Cache values to populate the next request on the same stage
        # This is as we re-render the same page if only some requests have been updated.
        @values = params[:descriptors]
      end

      # This is when we have a set of fields per-request (ie. Task#per_item == 1)
      if params.dig(:requests, request.id.to_s, :descriptors)
        # Descriptors: create description for event

        event.descriptors = params[:requests][request.id.to_s][:descriptors].to_unsafe_hash
      end

      # Save the event
      event.save

      # Some receptacles are flagged as 'resource'. There are 43 of these in the production database,
      # all are from 2009 - 2010.
      # For all other assets we create an {Event} alongside the {LabEvent}
      # I don't think we actually trigger any special behaviour here, so this is just tracking.
      # These aren't linked to the event WH, but are exposed on the event history page.
      EventSender.send_request_update(request, 'update', "Passed: #{@task.name}") unless request.asset.try(:resource)
    end

    if @batch.requests.all? { |request| request.has_passed(@batch, @task) || request.failed? }
      eventify_batch @batch, @task
      true
    else
      # Some requests have yet to pass this task
      # Construct a URL that contains a nested hash of values to display as defaults for the next request
      @params = { batch_id: @batch.id, workflow_id: @workflow.id, values: @values }
      redirect_to url_for(flatten_hash(@params))
      false
    end
  end

  # rubocop:enable Metrics/AbcSize
  # rubocop:enable Metrics/MethodLength
  # rubocop:enable Metrics/PerceivedComplexity

  def render_set_descriptors_task(_task, params) # rubocop:todo Metrics/AbcSize
    @batch = Batch.includes(:requests, :pipeline, :lab_events).find(params[:batch_id])
    @rits = @batch.pipeline.request_information_types
    @requests = @batch.ordered_requests
    @workflow = Workflow.includes(:tasks).find(params[:workflow_id])
    @task = @workflow.tasks[params[:id].to_i]
    @stage = params[:id].to_i
    @values = params[:values].nil? ? {} : params[:values]
  end
end
