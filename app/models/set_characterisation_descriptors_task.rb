# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2011,2015 Genome Research Ltd.

class SetCharacterisationDescriptorsTask < Task
  def partial
    'set_characterisation_descriptors'
  end

  def render_task(workflows_controller, params)
    super
    workflows_controller.render_set_characterisation_descriptors_task(self, params)
  end

  def do_task(workflows_controller, params)
    workflows_controller.do_set_characterisation_descriptors_task(self, params)
  end

  def sub_events_for_event(event)
    return [] unless event.eventful.respond_to?(:asset)
    subassets = subassets_for_asset(event.eventful.asset).select do |asset|
      # we don't want anything except fragment gel so far ...
      asset.is_a?(Fragment) && name == 'Gel'
    end
    subassets.map { |a| generate_events_from_descriptors(a) }
  end
end
