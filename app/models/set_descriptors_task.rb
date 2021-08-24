# The SetDescriptorsTask presents a series of configured {Descriptor descriptors}
# to the user, and lets them specify values for them. These values are the record
# in {LabEvent lab events} created for each {Request}.
#
# The per_item attribute, specifies whether the user is presented with a separate
# set of descriptors for each request, or if they are shared across the {Batch}.
# In either case, the user can deselect individual requests from a table at the top
# of the screen, to only apply their attributes to a subset of requests.
class SetDescriptorsTask < Task
  # The Setter handles the processing of each task, and actually performs the
  # actions.
  class DescriptorSetter
    attr_reader :controller, :params, :task

    delegate :requests, to: :batch

    def initialize(controller:, params:, task:)
      @controller = controller
      @params = params
      @task = task
    end

    def render
      controller.render_set_descriptors_task(task, params)
    end

    def perform
      # Process each request that has been checked.

      requests.each do |request|
        next unless checked_requests.include?(request.id)
        process_request(request)
      end

      return false unless all_requests_processed?
      create_batch_events
      batch.save
      true
    end

    private

    def process_request(request)
      LabEvent.create!(
        batch: batch,
        description: @task.name,
        descriptors: descriptors(request),
        user: current_user,
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
    #   <input value="testing" id="descriptor_0_" type="text" name="descriptors[Operator]">
    # This results in:
    #   params[:descriptors] => <ActionController::Parameters {"Operator"=>"operator_value", ...} permitted: true>
    # which gets reused for each request
    ## Per request:
    # A separate hash is generated per request.
    # The fields look like this:
    #   <input value="" id="descriptor_0_123" type="text" name="requests[123][descriptors][Concentration]">
    # Which results in:
    #   params[:requests] =><ActionController::Parameters {
    #     "131"=><ActionController::Parameters {"descriptors"=><ActionController::Parameters {"Concentration"=>"1.2"} permitted: true>} permitted: true>,
    #     "132"=><ActionController::Parameters {"descriptors"=><ActionController::Parameters {"Concentration"=>"2.2"} permitted: true>} permitted: true>
    #  }
    def descriptors(request)
      (params[:descriptors].presence || params.dig(:requests, request.id.to_s, :descriptors))&.permit!&.to_hash || {}
    end

    def checked_requests
      # Front end renders checkboxes in the form:
      # <input name="request[20251826]" id="sample 1 checkbox" class="sample_check select_all_target" value="on" type="checkbox" checked="">
      # We don't have hidden input fields of the same name, so params[:request] looks as follows:
      # { '123' => 'on', '124' => 'on' }
      # Unchecked requests are *not* listed in the hash.
      @checked_requests ||= params.fetch(:request, {}).keys.map(&:to_i)
    end

    def current_user
      controller.send(:current_user)
    end

    def batch
      @batch ||= Batch.includes(:requests, :pipeline, :lab_events).find(params[:batch_id])
    end

    def create_batch_events
      event = batch.lab_events.build(description: 'Complete', user: current_user, batch: batch)
      event.add_descriptor Descriptor.new(name: 'task_id', value: task.id)
      event.add_descriptor Descriptor.new(name: 'task', value: task.name)
      event.save!
    end
  end

  def partial
    'set_descriptors'
  end

  def can_process?(batch, from_previous: false)
    batch.released? ? [true, 'Edit'] : [true, nil]
  end

  def render_task(workflows_controller, params)
    DescriptorSetter.new(controller: workflows_controller, params: params, task: self).render
  end

  def do_task(workflows_controller, params)
    DescriptorSetter.new(controller: workflows_controller, params: params, task: self).perform
  end

  #
  # Returns an array of {Descriptor} objects for the task, populated with the values for
  # the most recent matching {LabEvent} on the {Request}
  # @note We can't just use LabEvent#descriptors as it doesn't return type information
  #
  # @param request [Request] The request to find the values for
  #
  # @return [Array<Descriptor>] Array of descriptors with appropriate values
  #
  def descriptors_for(request)
    descriptors_with_values(descriptor_hash_for(request))
  end

  #
  # Returns an array of {Descriptor} objects for the task, populated with the values
  # from the provided hash
  #
  # @param values [Hash<String:String>] Hash of key-value pairs
  #
  # @return [Array<Descriptor>] Array of descriptors with appropriate values
  #
  def descriptors_with_values(values)
    descriptors.map do |descriptor|
      descriptor.dup.tap do |valued_descriptor|
        valued_descriptor.value = values.fetch(descriptor.name, descriptor.value)
      end
    end
  end

  # Returns true if we should collect descriptors per request.
  # Always true if {#per_item} is true, otherwise true if requests have different
  # values
  def per_item_for(requests)
    per_item || requests.map { |request| descriptor_hash_for(request) }.uniq.many?
  end

  private

  def descriptor_hash_for(request)
    request.most_recent_event_named(name)&.descriptor_hash || {}
  end
end
