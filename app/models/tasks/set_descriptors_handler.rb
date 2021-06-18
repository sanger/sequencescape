module Tasks::SetDescriptorsHandler # rubocop:todo Style/Documentation
  # rubocop:todo Metrics/PerceivedComplexity
  # rubocop:todo Metrics/MethodLength
  # rubocop:todo Metrics/AbcSize
  def do_set_descriptors_task(_task, params) # rubocop:todo Metrics/CyclomaticComplexity
    @batch = Batch.includes(:requests, :pipeline, :lab_events).find(params[:batch_id])

    # Determines files shown on the table at the top of the page
    @rits = @batch.pipeline.request_information_types
    @requests = @batch.ordered_requests

    # If qc_state is qc_manual then update it
    # @note Only seems to have been used over a 7 month period between
    #       2009-12-09 14:53:15 and 2010-06-16 12:20:11
    #       Not sure why its duplicated.
    #       I believe we originally had additional tasks within SS that would be
    #       performed after the run had been processed.
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
      # Here we pass over each request in the batch, and for each request, loop through
      # the checked parameters, to find out if they match. If they do, we process that request.
      # Regardless, we check to see if each request has been processed by this task, as it may
      # have done so on a previous attempt.

      @batch.requests.each do |request|
        unless params[:request].nil?
          # Front end renders checkboxes in the form:
          # <input name="request[20251826]" id="sample 1 checkbox" class="sample_check select_all_target" value="on" type="checkbox" checked="">
          # We don't have hidden input fields of the same name, so params[:request] looks as follows:
          # { '123' => 'on', '124' => 'on' }
          # Unchecked requests are *not* listed in the hash.
          params[:request].keys.each do |checked|
            # This is used to see if any check boxes are set on when the page is rendered with
            # with a single set of descriptor fields is shared between all the requests...
            if request.id == checked.to_i
              event = LabEvent.new(batch_id: @batch.id, description: @task.name)

              # This is called when a single set of fields is used (ie. Task#per_item == 0)
              # and called over and over based on the selected requests
              # The fields for a descriptor look like this:
              # <td width="65%">
              #   <input value="" type="text" name="descriptors[Operator]" id="descriptors_Operator">
              #   <input value="Operator" type="hidden" name="fields[1]" id="fields_1">
              # </td>
              # This results in:
              # params[:descriptors] => <ActionController::Parameters {"Operator"=>"operator_value", "Workflow (Standard or Xp)"=>"Standard", "DPX1"=>"dpx1_value", "DPX2"=>"dpx2_value", "DPX3"=>"dpx3_value", "NovaSeq%20Xp%20Mainfold"=>"nov_seq_xp_val", "Pipette%20Carousel"=>"pippet_val", "PhiX%20lot%20%23"=>"phix_val", "PhiX%20%25"=>"Phix%_val", "Lane%20loading%20concentration%20%28pM%29"=>"lan_conc_val", "Comment"=>"comment_val"} permitted: true>
              # params[:fields] => <ActionController::Parameters {"1"=>"Operator", "2"=>"Workflow (Standard or Xp)", "3"=>"DPX1", "4"=>"DPX2", "5"=>"DPX3", "6"=>"NovaSeq Xp Mainfold", "7"=>"Pipette Carousel", "8"=>"PhiX lot #", "9"=>"PhiX %", "10"=>"Lane loading concentration (pM)", "11"=>"Comment"} permitted: true>
              # I believe that some of this complexity predates ordered hashes in ruby, and was an attempt to maintain field order.
              unless params[:descriptors].nil?
                event.descriptors = params[:descriptors]
                event.descriptor_fields = ordered_fields(params[:fields])

                # Cache values to populate the next request on the same stage
                # This is as we re-render the same page if only some requests have been updated.
                event.descriptors.each { |descriptor| @values[descriptor.name] = descriptor.value }
              end

              # This is when we have a set of fields per-request (ie. Task#per_item == 1)
              if !params[:requests].nil? && !params[:requests][(request.id).to_s].nil? &&
                   !params[:requests][(request.id).to_s][:descriptors].nil?
                # Descriptors: create description for event

                event.descriptors = params[:requests][(request.id).to_s][:descriptors]
                event.descriptor_fields = ordered_fields(params[:requests][(request.id).to_s][:fields])
              end

              # Handles file upload. Never used, seems to have been intended to trigger
              # if a task had the {Descriptor} with the kind` 'File upload' of which we have
              # none
              if params[:upload].present?
                params[:upload].each do |key, uploaded|
                  event.filename = uploaded.original_filename.gsub(/[^a-zA-Z0-9.]/, '_')
                  event.data = uploaded.read
                  event.add_descriptor Descriptor.new(name: key, value: event.filename)
                end
              end

              # Save the event
              event.save

              # Add it to the user, but users have_many :lab_events, and lab_events belong_to user, so this is equivalent
              # of just event.user = current_user, which we could even do when we initialize the event.
              current_user.lab_events << event

              # Add it to the request, which have many events as eventful, so this is equivalent of just setting
              # event.eventful to the request
              request.lab_events << event

              # Some receptacles are flagged as 'resource'. There are 43 of these in the production database,
              # all are from 2009 - 2010.
              # For all other assets we create an {Event} alongside the {LabEvent}
              # I don't think we actually trigger any special behaviour here, so this is just tracking.
              # These aren't linked to the event WH, but are exposed on the event history page.
              unless request.asset.try(:resource)
                EventSender.send_request_update(request, 'update', "Passed: #{@task.name}")
              end
            end
          end
        end

        # We record how many requests have been through this step.
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
