# The task associated with this module is no-longer used. I've been working on
# removing it in another branch.
module Tasks::SetCharacterisationDescriptorsHandler
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
      create_batch_events @batch, @task
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

  private

  # Moved the methods below from the workflows controller as they are now only
  # used here, and can be safely removed along with the rest of this tasks code.

  # Flattens nested hashes down into a single layer in a similar manner
  # to rails form parameter naming.
  # @example Flattening a hash multiple levels deep
  #   flatten_hash(key: 'value', key2: { key2a: 'value2a', key2b: 'value2b', key2c: { nested: 'deep'}})
  #   # => {"key"=>"value", "key2[key2a]"=>"value2a", "key2[key2b]"=>"value2b", "key2[key2c][nested]"=>"deep"}
  #
  # @example Flattening a hash with ancestors
  #   flatten_hash({key: 'value', key2: { key2a: 'value2a', key2b: 'value2b'}}, [:ancestor])
  # # => {"ancestor[key]"=>"value", "ancestor[key2][key2a]"=>"value2a", "ancestor[key2][key2b]"=>"value2b"}
  #
  # @param hash [Hash] The hash to flatten
  # @param ancestor_names [Array] Ancestors for all keys in the hash
  #
  # @return [type] [description]
  def flatten_hash(hash = params, ancestor_names = []) # rubocop:todo Metrics/MethodLength
    flat_hash = {}
    hash.each do |k, v|
      names = [*ancestor_names, k]
      if v.is_a?(Hash)
        flat_hash.merge!(flatten_hash(v, names))
      else
        key = flat_hash_key(names)
        key += '[]' if v.is_a?(Array)
        flat_hash[key] = v
      end
    end

    flat_hash
  end

  def flat_hash_key(keys)
    keys.reduce { |flattened_keys, key| flattened_keys << "[#{key}]" }
  end
end
