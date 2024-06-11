# frozen_string_literal: true
# The SetDescriptorsTask presents a series of configured {Descriptor descriptors}
# to the user, and lets them specify values for them. These values are the record
# in {LabEvent lab events} created for each {Request}.
#
# The per_item attribute, specifies whether the user is presented with a separate
# set of descriptors for each request, or if they are shared across the {Batch}.
# In either case, the user can deselect individual requests from a table at the top
# of the screen, to only apply their attributes to a subset of requests.
class SetDescriptorsTask < Task
  def partial
    'set_descriptors'
  end

  def can_process?(batch)
    batch.released? ? [true, 'Edit'] : [true, nil]
  end

  def render_task(workflows_controller, params, user)
    Tasks::SetDescriptorsHandler::Handler.new(controller: workflows_controller, params:, task: self, user:)
      .render
  end

  def do_task(workflows_controller, params, user)
    Tasks::SetDescriptorsHandler::Handler.new(controller: workflows_controller, params:, task: self, user:)
      .perform
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
