# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2011,2013,2015 Genome Research Ltd.

module Tasks::SetCharacterisationDescriptorsHandler
  def do_set_characterisation_descriptors_task(_task, params)
    @count = 0
    if params[:values].nil?
      @values = {}
    else
      @values = params[:values]
    end

    # Perform the necessary updates if we've passed batch creation
    updated = 0

    @batch.requests.each do |request|
      event = LabEvent.new(batch_id: @batch.id, description: @task.name)

      if params[:requests].present? && params[:requests][(request.id).to_s].present? && params[:requests][(request.id).to_s][:descriptors].present?
        # Descriptors: create description for event

        event.descriptors = params[:requests][(request.id).to_s][:descriptors]
        event.descriptor_fields = ordered_fields(params[:requests][(request.id).to_s][:fields])

      end

      event.save!
      current_user.lab_events << event
      request.lab_events << event

      unless request.asset.try(:resource)
        EventSender.send_request_update(request.id, 'update', "Passed: #{@task.name}")
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
      @params = { batch_id: @batch.id, workflow_id: @workflow.id, values: @values }
      redirect_to url_for(flatten_hash(@params))
    end

    false
  end

  def render_set_characterisation_descriptors_task(_task, params)
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
