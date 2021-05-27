module Tasks::SetDescriptorsHandler # rubocop:todo Style/Documentation
  # rubocop:todo Metrics/PerceivedComplexity
  # rubocop:todo Metrics/MethodLength
  # rubocop:todo Metrics/AbcSize
  def do_set_descriptors_task(_task, params) # rubocop:todo Metrics/CyclomaticComplexity
    @batch = Batch.includes(:requests, :pipeline, :lab_events).find(params[:batch_id])
    @rits = @batch.pipeline.request_information_types
    @requests = @batch.ordered_requests

    # if qc_state is qc_manual then update it
    if @batch.qc_state == 'qc_manual'
      @batch.lab_events.create(
        description: 'Manual QC',
        message: "Manual QC started for batch #{@batch.id}",
        user_id: current_user.id
      )
      @batch.lab_events.create(
        description: 'Manual QC',
        message: "Manual QC started for batch #{@batch.id}",
        user_id: current_user.id
      )
      @batch.qc_state = @batch.qc_next_state
      @batch.save
    end

    @workflow = Workflow.includes(:tasks).find(params[:workflow_id])
    @task = @workflow.tasks[params[:id].to_i]
    @stage = params[:id].to_i
    @count = 0
    @values = params[:values].nil? ? {} : params[:values]

    # Perform the necessary updates if we've passed batch creation
    unless params[:next_stage].nil?
      updated = 0

      # rubocop:todo Metrics/BlockLength
      # rubocop:todo Metrics/BlockNesting
      @batch.requests.each do |request|
        unless params[:request].nil?
          params[:request].keys.each do |checked|
            # This is used to see if any check boxes are set on when the page is rendered with
            # with a single set of descriptor fields is shared between all the requests...
            if request.id == checked.to_i
              event = LabEvent.new(batch_id: @batch.id, description: @task.name)

              # This is called when a single set of fields is used
              # and called over and over based on the select boxs
              unless params[:descriptors].nil?
                event.descriptors = params[:descriptors]
                event.descriptor_fields = ordered_fields(params[:fields])

                # Cache values to populate the next request on the same stage
                event.descriptors.each { |descriptor| @values[descriptor.name] = descriptor.value }
              end

              if !params[:requests].nil? && !params[:requests][(request.id).to_s].nil? &&
                   !params[:requests][(request.id).to_s][:descriptors].nil?
                # Descriptors: create description for event

                event.descriptors = params[:requests][(request.id).to_s][:descriptors]
                event.descriptor_fields = ordered_fields(params[:requests][(request.id).to_s][:fields])
              end

              if params[:upload].present?
                params[:upload].each do |key, uploaded|
                  event.filename = uploaded.original_filename.gsub(/[^a-zA-Z0-9.]/, '_')
                  event.data = uploaded.read
                  event.add_descriptor Descriptor.new(name: key, value: event.filename)
                end
              end

              event.save
              current_user.lab_events << event
              request.lab_events << event

              unless request.asset.try(:resource)
                EventSender.send_request_update(request, 'update', "Passed: #{@task.name}")
              end
            end
          end
        end

        updated += 1 if request.has_passed(@batch, @task) || request.failed?
      end

      # rubocop:enable Metrics/BlockLength
      # rubocop:enable Metrics/BlockNesting
      if updated == @batch.requests.count
        eventify_batch @batch, @task
        return true
      else
        # Some requests have yet to pass this task
        # Construct a URL that contains a nested hash of values to display as defaults for the next request
        @params = { batch_id: @batch.id, workflow_id: @workflow.id, values: @values }
        redirect_to url_for(flatten_hash(@params))
      end
    end
    false
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
    @count = 0
    @values = params[:values].nil? ? {} : params[:values]
  end
end
