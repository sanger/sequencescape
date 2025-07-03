# frozen_string_literal: true
module Tasks::SetDescriptorsHandler
  # The Setter handles the processing of each task, and actually performs the
  # actions.
  class Handler < Tasks::BaseHandler
    def render
      controller.render_set_descriptors_task(task, params)
    end

    def perform
      # Process each request that has been selected in the front end
      # by default all requests are selected, but in rare circumstances the user
      # can uncheck a request to exclude it from the step
      requests.each do |request|
        next unless selected_requests.include?(request.id)

        process_request(request)
      end

      return false unless all_requests_processed?

      create_batch_events

      # We touch the batch to ensure any flowcell messages have an updated timestamp
      batch.touch # rubocop:disable Rails/SkipsModelValidations
      true
    end

    private

    def params
      @params.respond_to?(:permit!) ? @params.permit!.to_h : @params
    end

    def process_request(request)
      LabEvent.create!(
        batch: batch,
        description: @task.name,
        descriptors: descriptors(request),
        user: user,
        eventful: request
      )

      # Some receptacles are flagged as 'resource'. There are 43 of these in the production database,
      # all are from 2009 - 2010.
      # For all other assets we create an {Event} alongside the {LabEvent}
      # I don't think we actually trigger any special behaviour here, so this is just tracking.
      # These aren't linked to the event WH, but are exposed on the event history page.
      EventSender.send_request_update(request, 'update', "Passed: #{@task.name}") unless request.asset.try(:resource)
    end

    def all_requests_processed?
      requests.all? { |request| request.has_passed(batch, @task) || request.failed? }
    end

    # Descriptors can either be supplied per batch (ie. Task#per_item == 0) or
    # per request (ie. Task#per_item == 1)
    ## Per batch:
    # The fields for a descriptor look like this:
    #   <input value="testing" id="descriptor_0_" type="text" name="descriptors[Comment]">
    # This results in:
    #   params[:descriptors] => <ActionController::Parameters {"Comment"=>"comment_value", ...} permitted: true>
    # which gets reused for each request
    ## Per request:
    # A separate hash is generated per request.
    # The fields look like this:
    #   <input value="" id="descriptor_0_123" type="text" name="requests[123][descriptors][Concentration]">
    # Which results in:
    #   params[:requests] =><ActionController::Parameters {
    #     "131"=><ActionController::Parameters {"descriptors"=><ActionController::Parameters {"Concentration"=>"1.2"}
    #                                            permitted: true>} permitted: true>,
    #     "132"=><ActionController::Parameters {"descriptors"=><ActionController::Parameters {"Concentration"=>"2.2"}
    #                                            permitted: true>} permitted: true>
    #  }
    def descriptors(request)
      (params[:descriptors].presence || params.dig(:requests, request.id.to_s, :descriptors)) || {}
    end

    def batch
      @batch ||= Batch.includes(:requests, :pipeline, :lab_events).find(params[:batch_id])
    end
  end

  def render_set_descriptors_task(_task, params)
    @batch = Batch.includes(:requests, :pipeline, :lab_events).find(params[:batch_id])
    @rits = @batch.pipeline.request_information_types
    @requests = @batch.ordered_requests
    @workflow = Workflow.includes(:tasks).find(params[:workflow_id])
    @task = @workflow.tasks[params[:id].to_i]
  end
end
