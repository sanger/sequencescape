# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2007-2011,2013,2015 Genome Research Ltd.

module Tasks::SetDescriptorsHandler
  def do_set_descriptors_task(_task, params)
    @batch = Batch.includes(:requests, :pipeline, :lab_events).find(params[:batch_id])
    @rits = @batch.pipeline.request_information_types
    @requests = @batch.ordered_requests

    # if qc_state is qc_manual then update it
    if @batch.qc_state == 'qc_manual'
      @batch.lab_events.create(description: 'Manual QC', message: "Manual QC started for batch #{@batch.id}", user_id: current_user.id)
      @batch.lab_events.create(description: 'Manual QC', message: "Manual QC started for batch #{@batch.id}", user_id: current_user.id)
      @batch.qc_state = @batch.qc_next_state
      @batch.save
    end

    @workflow = LabInterface::Workflow.includes(:tasks).find(params[:workflow_id])
    @task = @workflow.tasks[params[:id].to_i]
    @stage = params[:id].to_i
    @count = 0
    if params[:values].nil?
      @values = {}
    else
      @values = params[:values]
    end

    # Perform the necessary updates if we've passed batch creation
    unless params[:next_stage].nil?
      updated = 0

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
                event.descriptors.each do |descriptor|
                  @values[descriptor.name] = descriptor.value
                end
              end

              if !params[:requests].nil? && !params[:requests][(request.id).to_s].nil? && !params[:requests][(request.id).to_s][:descriptors].nil?
                # Descriptors: create description for event

                event.descriptors = params[:requests][(request.id).to_s][:descriptors]
                event.descriptor_fields = ordered_fields(params[:requests][(request.id).to_s][:fields])

              end

              unless params[:upload].nil?
                params[:upload].each_key do |key|
                  event.filename = params[:upload][key].original_filename.gsub(/[^a-zA-Z0-9.]/, '_')
                  event.data = params[:upload][key].read
                  event.add_descriptor Descriptor.new(name: key, value: event.filename)
                end
              end

              event.save
              current_user.lab_events << event
              request.lab_events << event

              if params[:asset]
                params[:asset].keys.each do |key|
                  asset = Asset.new
                  asset.sti_type = Family.find(params[:asset][key][:family_id]).name
                  params[:asset][key].each_key do |field|
                    asset.add_descriptor Descriptor.new(name: field, value: params[:asset][key][field])
                  end
                  asset.save
                  asset.parents << request.asset
                end
              end

              unless request.asset.try(:resource)
                EventSender.send_request_update(request.id, 'update', "Passed: #{@task.name}")
              end
            end
          end
        end

        if request.has_passed(@batch, @task) || request.failed?
          updated += 1
        end
      end

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

  def render_set_descriptors_task(_task, params)
    @batch = Batch.includes(:requests, :pipeline, :lab_events).find(params[:batch_id])
    @rits = @batch.pipeline.request_information_types
    @requests = @batch.ordered_requests
    @workflow = LabInterface::Workflow.includes(:tasks).find(params[:workflow_id])
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
