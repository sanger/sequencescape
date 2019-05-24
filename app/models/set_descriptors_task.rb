class SetDescriptorsTask < Task
  def render_task(workflows_controller, params)
    super
    workflows_controller.render_set_descriptors_task(self, params)
  end

  def do_task(workflows_controller, params)
    workflows_controller.do_set_descriptors_task(self, params)
  end

  # Extracts descriptors (now metadata) from assets and generates mock events.
  # Appears to be unused. Awaiting confirmation from eh9 (mq1 already confirmed)
  def sub_events_for_event(event)
    return [] unless event.eventful.respond_to?(:asset)

    subassets = subassets_for_asset(event.eventful.asset).select do |asset|
      # we don't want anything except fragment gel so far ...
      asset.is_a?(Fragment) && name == 'Gel'
    end
    subassets.map { |a| generate_events_from_descriptors(a) }
  end
end
